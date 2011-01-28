module XYZ
  module CloneClassMixins
    def clone(id_handle,target_id_handle,override_attrs={},opts={})
      add_model_specific_override_attrs!(override_attrs)
      new_id_handle = clone_copy(id_handle,[target_id_handle],override_attrs,opts).first
      raise Error.new("cannot clone") unless new_id_handle
      #calling with respect to target
      model_class(target_id_handle[:model_name]).clone_post_copy_hook(new_id_handle,target_id_handle,opts)
      return new_id_handle.get_id()
    end

   protected
    # to be optionally overwritten by object representing the source
    def add_model_specific_override_attrs!(override_attrs)
    end

    # to be optionally overwritten by object representing the target
    def clone_post_copy_hook(new_id_handle,target_id_handle,opts={})
    end

   private

    #copy part of clone
    #targets is a list of id_handles, each with same model_name 
    def clone_copy(source_id_handle,targets,recursive_override_attrs={},opts={})
      fk_info = ForeignKeyInfo.new(db)
      return Array.new if targets.empty?

      source_model_name = source_id_handle[:model_name]
      source_model_handle = source_id_handle.createMH()
      source_parent_id_col = source_model_handle.parent_id_field_name()

      override_attrs = ret_real_columns(source_model_handle,recursive_override_attrs)

      #all targets will have same model handle
      sample_target =  targets.first
      target_parent_mh = sample_target.createMH()
      target_mh = source_id_handle.createMH(:parent_model_name => target_parent_mh[:model_name])
      target_parent_id_col = target_mh.parent_id_field_name()
      targets_rows = targets.map{|id_handle|{target_parent_id_col => id_handle.get_id()}}
      targets_ds = SQL::ArrayDataset.create(db,targets_rows,ModelHandle.new(source_id_handle[:c],:target))

      source_wc = {:id => source_id_handle.get_id()}

      remove_cols = (source_parent_id_col == target_parent_id_col ? [:id,:local_id] : [:id,:local_id,source_parent_id_col])
      field_set_to_copy = Model::FieldSet.all_real(source_model_name).with_removed_cols(*remove_cols)
      fk_info.add_foreign_keys(source_model_handle,field_set_to_copy)
      source_fs = Model::FieldSet.opt(field_set_to_copy.with_removed_cols(target_parent_id_col))
      source_ds = get_objects_just_dataset(source_model_handle,source_wc,source_fs)

      select_ds = targets_ds.join_table(:inner,source_ds)
      create_override_attrs = override_attrs.merge(:ancestor_id => source_id_handle.get_id()) 

      new_objs_info = create_from_select(target_mh,field_set_to_copy,select_ds,create_override_attrs,create_opts_for_top())
      return Array.new if new_objs_info.empty?
      fk_info.add_id_mappings(source_model_handle,new_objs_info)
      new_id_handles = ret_id_handles_from_create_returning_ids(target_mh,new_objs_info)
      fk_info.add_id_handles(new_id_handles) #TODO: may be more efficient adding only id handles assciated with foreign keys

      #iterate over all nested objects which includes children object plus, for example, components for composite components
      get_nested_objects__all(source_model_handle,target_parent_mh,new_objs_info,recursive_override_attrs).each do |child_context|
        child_id_handles = clone_copy_child_objects(fk_info,child_context)
        fk_info.add_id_handles(child_id_handles)
      end
      fk_info.shift_foregn_keys()
      new_id_handles
    end

    def get_nested_objects__parents(model_handle,objs_info,recursive_override_attrs)
      model_handle.get_children_model_handles().map do |mh|
        override_attrs = ret_child_override_attrs(mh,recursive_override_attrs)
        parent_id_col = mh.parent_id_field_name()
        parent_rels = objs_info.map{|row|{parent_id_col => row[:id],:old_par_id => row[:ancestor_id]}}
        create_opts = {:duplicate_refs => :no_check, :returning_sql_cols => [:ancestor_id]}
        {:model_handle => mh, :parent_shift_col => parent_id_col, :parent_rels => parent_rels, :override_attrs => override_attrs, :create_opts => create_opts}
      end
    end

    def get_nested_objects__all(model_handle,target_parent_mh,objs_info,recursive_override_attrs,opts={})
      ret = get_nested_objects__parents(model_handle,objs_info,recursive_override_attrs)
      target_parent_mn = target_parent_mh[:model_name]
      model_name = model_handle[:model_name]
      parent_id_col = DB.parent_field(target_parent_mn,model_name)
      create_opts = {:duplicate_refs => :allow, :returning_sql_cols => [:ancestor_id]}
      return ret if true #TODO: to test opts[:no_non_parent_children]
      (InvertedNonParentNestedKeys[model_handle[:model_name]]||{}).each do |nested_model_name, par_shift_col|
        nested_mh = ModelHandle.new(model_handle[:c],nested_model_name) #important that parent_model_name not (incorrectly) set
        override_attrs = ret_child_override_attrs(nested_mh,recursive_override_attrs)
        common_settings = (DB_REL_DEF[nested_model_name][:many_to_one]||[]).inject({}) do |hash,pos_par|
          hash.merge(pos_par == target_parent_mn ? {DB.parent_field(pos_par,model_name) => nil} : {})
        end
        parent_rels = objs_info.map do |row|
          common_settings.merge(par_shift_col => row[:id],:old_par_id => row[:ancestor_id], parent_id_col => row[:parent_id])
        end
        ret << {:model_handle => nested_mh, :parent_shift_col => par_shift_col, :parent_rels => parent_rels, :override_attrs => override_attrs, :create_opts => create_opts}
      end
      ret
    end
    NonParentNestedKeys = {
      :component => {:assembly_id => :component},
      :node => {:assembly_id => :component},
      :attribute_link => {:assembly_id => :component}
    }

    InvertedNonParentNestedKeys = NonParentNestedKeys.inject({}) do |ret,kv|
      kv[1].each do |col,m|
        ret[m] ||= Hash.new
        ret[m][kv[0]] = col
      end
      ret
    end

    def clone_copy_child_objects(fk_info,child_context)
      child_model_handle = child_context[:model_handle]
      parent_rels = child_context[:parent_rels]
      recursive_override_attrs= child_context[:override_attrs]
      child_model_name = child_model_handle[:model_name]
      par_shift_col = child_context[:parent_shift_col]

      ancestor_rel_ds = SQL::ArrayDataset.create(db,parent_rels,child_model_handle.createMH(:model_name => :target))

      field_set_to_copy = Model::FieldSet.all_real(child_model_name).with_removed_cols(:id,:local_id)
      fk_info.add_foreign_keys(child_model_handle,field_set_to_copy)
      field_set_from_ancestor = field_set_to_copy.with_removed_cols(:ancestor_id,par_shift_col).with_added_cols({:id => :ancestor_id},{par_shift_col => :old_par_id})
      child_wc = nil
      child_ds = get_objects_just_dataset(child_model_handle,child_wc,Model::FieldSet.opt(field_set_from_ancestor))

      select_ds = ancestor_rel_ds.join_table(:inner,child_ds,[:old_par_id])
      create_override_attrs = ret_real_columns(child_model_handle,recursive_override_attrs)
      new_objs_info = create_from_select(child_model_handle,field_set_to_copy,select_ds,create_override_attrs,child_context[:create_opts])
      return Array.new if new_objs_info.empty?
      fk_info.add_id_mappings(child_model_handle,new_objs_info)
      new_id_handles = ret_id_handles_from_create_returning_ids(child_model_handle,new_objs_info)

      ret = new_id_handles
      #iterate all nested children
      get_nested_objects__parents(child_model_handle,new_objs_info,recursive_override_attrs).each do |child_context|
        child_id_handles = clone_copy_child_objects(fk_info,child_context)
        ret += child_id_handles
      end
      #unlike top level fn; this returns also nested id handles
      ret
    end

    def create_opts_for_top()
      dups_allowed_for_cmp = true #TODO stub
      returning_sql_cols = [:ancestor_id] 
      returning_sql_cols << :type if model_name == :component
      {:duplicate_refs => dups_allowed_for_cmp ? :allow : :prune_duplicates,:returning_sql_cols => returning_sql_cols}
    end

    def ret_child_override_attrs(child_model_handle,recursive_override_attrs)
      recursive_override_attrs[(child_model_handle[:model_name])]||{}
    end
    def ret_real_columns(model_handle,recursive_override_attrs)
      fs = Model::FieldSet.all_real(model_handle[:model_name])
      recursive_override_attrs.reject{|k,v| not fs.include_col?(k)}
    end

    class ForeignKeyInfo
      def initialize(db)
        @info = Hash.new
        @db = db
      end

      def add_id_handles(new_id_handles)
        new_id_handles.each do |idh|
          model_handle_info(idh)[:new_ids] << idh.get_id() 
        end
      end

    def shift_foregn_keys()
#TODO: not working right yet
return nil
      each_fk do |model_handle, fk_model_name, fk_cols|
        #get (if the set of id mappings for fk_model_name
        id_mappings = get_id_mappings(model_handle,fk_model_name)
        next if id_mappings.empty?
          #TODO: may be more efficient to shift multiple fk cols at same time
          fk_cols.each{|fk_col|shift_foregn_keys_aux(model_handle,fk_col,id_mappings)}
        end
      end

      def add_id_mappings(model_handle,objs_info)
        model_index = model_handle_info(model_handle)
        model_index[:id_mappings] = model_index[:id_mappings]+objs_info.map{|x|Aux::hash_subset(x,[:id,:ancestor_id])}
      end

      def add_foreign_keys(model_handle,field_set)
        #TODO: only putting in once per model; not sure if need to treat instances differently; if not can do this alot more efficiently computing just once
        fks = model_handle_info(model_handle)[:fks]
        #put in foreign keys that are not special keys like ancestor or assembly_id
        omit = ForeignKeyOmissions[model_handle[:model_name]]||[]
        field_set.foreign_key_info().each do |fk,fk_info|
          next if fk == :ancestor_id or omit.include?(fk)
          pointer = fks[fk_info[:foreign_key_rel_type]] ||= Array.new
          pointer << fk unless pointer.include?(fk)
        end
      end
     private
      ForeignKeyOmissions = CloneClassMixins::NonParentNestedKeys.inject({}) do |ret,kv|
        ret.merge(kv[0] => kv[1].keys)
      end

      def shift_foregn_keys_aux(model_handle,fk_col,id_mappings)
        model_name = model_handle[:model_name]
        base_fs = Model::FieldSet.opt([:id,{fk_col => :old_key}],model_name)
        base_wc = SQL.in(:id,model_handle_info(model_handle)[:new_ids])
        base_ds = Model.get_objects_just_dataset(model_handle,base_wc,base_fs)

        mappping_rows = id_mappings.map{|r| {fk_col => r[:id], :old_key => r[:ancestor_id]}}
        mapping_ds = SQL::ArrayDataset.create(@db,mappping_rows,model_handle.createMH(:model_name => :mappings))
        select_ds = base_ds.join_table(:inner,mapping_ds,[:old_key])

        field_set = Model::FieldSet.new(model_name,[fk_col])
        Model.update_from_select(model_handle,field_set,select_ds)
      end

      def model_handle_info(mh)
        @info[mh[:c]] ||= Hash.new
        @info[mh[:c]][mh[:model_name]] ||= {:id_mappings => Array.new, :fks => Hash.new, :new_ids => Array.new}
      end

      def each_fk(&block)
        @info.each do |c,rest|
          rest.each do |model_name, hash|
            hash[:fks].each do |fk_model_name, fk_cols|
              block.call(ModelHandle.new(c,model_name),fk_model_name, fk_cols)
            end
          end
        end
      end
      
      def get_id_mappings(mh,fk_model_name)
        ((@info[mh[:c]]||{})[fk_model_name]||{})[:id_mappings] || Array.new
      end

    end
  end
end
