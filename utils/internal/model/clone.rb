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
      fk_info = ForeignKeyInfo.new()
      return Array.new if targets.empty?

      source_model_name = source_id_handle[:model_name]
      source_model_handle = source_id_handle.createMH()
      source_parent_id_col = source_model_handle.parent_id_field_name()

      override_attrs = ret_real_columns(source_model_handle,recursive_override_attrs)

      target_parent_model_name = targets.first[:model_name]
      target_model_handle = source_id_handle.createMH(:parent_model_name => target_parent_model_name)
      target_parent_id_col = target_model_handle.parent_id_field_name()
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
      new_objs_info = create_from_select(target_model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts_for_top())
      fk_info.add_id_mappings(source_model_handle,new_objs_info)
      return Array.new if new_objs_info.empty?
      new_id_handles = ret_id_handles_from_create_returning_ids(target_model_handle,new_objs_info)

      #iterate over all nested objects which includes children object plus, for example, components for composite components
      get_nested_objects_context(source_model_handle,new_objs_info).each do |child_context|
        child_model_handle = child_context[:model_handle]
        ancestor_parent_rels = child_context[:ancestor_parent_rels]
        child_override_attrs = ret_child_override_attrs(child_model_handle,recursive_override_attrs)
        clone_copy_child_objects2(fk_info,child_model_handle,ancestor_parent_rels,child_override_attrs)
      end
      new_id_handles
    end

    def get_nested_objects_context(model_handle,objs_info)
      model_handle.get_children_model_handles().map do |mh|
        child_parent_id_col = mh.parent_id_field_name()
        ancestor_parent_rels = objs_info.map{|row|{child_parent_id_col => row[:id],:parent_ancestor_id => row[:ancestor_id]}}
        {:model_handle => mh, :ancestor_parent_rels => ancestor_parent_rels}
      end
      #TODO: add rows for nested objects that are not parents
    end


    def clone_copy_child_objects2(fk_info,child_model_handle,ancestor_parent_rels,recursive_override_attrs={})
      #TODO: factor back in clone_helper or see if can use "insert-select mechanism"
      child_model_name = child_model_handle[:model_name]
      child_parent_id_col = child_model_handle.parent_id_field_name()

      ancestor_rel_ds = SQL::ArrayDataset.create(db,ancestor_parent_rels,child_model_handle.createMH(:model_name => :target))

      field_set_to_copy = Model::FieldSet.all_real(child_model_name).with_removed_cols(:id,:local_id)
      field_set_from_ancestor = field_set_to_copy.with_removed_cols(:ancestor_id,child_parent_id_col).with_added_cols({:id => :ancestor_id},{child_parent_id_col => :parent_ancestor_id})
      child_wc = nil
      child_ds = get_objects_just_dataset(child_model_handle,child_wc,Model::FieldSet.opt(field_set_from_ancestor))

      select_ds = ancestor_rel_ds.join_table(:inner,child_ds,[:parent_ancestor_id])
      create_override_attrs = ret_real_columns(child_model_handle,recursive_override_attrs)
      new_objs_info = create_from_select(child_model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts_for_child())
      return Array.new if new_objs_info.empty?
      new_id_handles = ret_id_handles_from_create_returning_ids(child_model_handle,new_objs_info)

      #iterate all nested children
      new_id_handles.first.get_children_model_handles.each do |child2_model_handle|
       child_override_attrs = ret_child_override_attrs(child2_model_handle,recursive_override_attrs)
        clone_copy_child_objects(child2_model_handle,new_objs_info,child_override_attrs)
      end

      new_id_handles
    end

    def clone_copy_child_objects(child_model_handle,ancestor_relation,recursive_override_attrs={})
      #TODO: factor back in clone_helper or see if can use "insert-select mechanism"
      child_model_name = child_model_handle[:model_name]
      child_parent_id_col = child_model_handle.parent_id_field_name()

      ancestor_rel_rows = ancestor_relation.map{|row|{child_parent_id_col => row[:id],:parent_ancestor_id => row[:ancestor_id]}}
      ancestor_rel_ds = SQL::ArrayDataset.create(db,ancestor_rel_rows,child_model_handle.createMH(:model_name => :target))

      field_set_to_copy = Model::FieldSet.all_real(child_model_name).with_removed_cols(:id,:local_id)
      field_set_from_ancestor = field_set_to_copy.with_removed_cols(:ancestor_id,child_parent_id_col).with_added_cols({:id => :ancestor_id},{child_parent_id_col => :parent_ancestor_id})
      child_wc = nil
      child_ds = get_objects_just_dataset(child_model_handle,child_wc,Model::FieldSet.opt(field_set_from_ancestor))

      select_ds = ancestor_rel_ds.join_table(:inner,child_ds,[:parent_ancestor_id])
      create_override_attrs = ret_real_columns(child_model_handle,recursive_override_attrs)
      new_objs_info = create_from_select(child_model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts_for_child())
      return Array.new if new_objs_info.empty?
      new_id_handles = ret_id_handles_from_create_returning_ids(child_model_handle,new_objs_info)

      #iterate all nested children
      new_id_handles.first.get_children_model_handles.each do |child2_model_handle|
       child_override_attrs = ret_child_override_attrs(child2_model_handle,recursive_override_attrs)
        clone_copy_child_objects(child2_model_handle,new_objs_info,child_override_attrs)
      end

      new_id_handles
    end


    #TODO: stubs
    def create_opts_for_top()
      dups_allowed_for_cmp = true #TODO stub
      returning_sql_cols = [:ancestor_id] 
      returning_sql_cols << :type if model_name == :component
      {:duplicate_refs => dups_allowed_for_cmp ? :allow : :prune_duplicates,:returning_sql_cols => returning_sql_cols}
    end
    def create_opts_for_child()
      {:duplicate_refs => :no_check, :returning_sql_cols => [:ancestor_id]}
    end

    def ret_child_override_attrs(child_model_handle,recursive_override_attrs)
      recursive_override_attrs[(child_model_handle[:model_name])]||{}
    end
    def ret_real_columns(model_handle,recursive_override_attrs)
      fs = Model::FieldSet.all_real(model_handle[:model_name])
      recursive_override_attrs.reject{|k,v| not fs.include_col?(k)}
    end

    class ForeignKeyInfo
      def initialize()
        @info = Hash.new
      end

      def add_id_mappings(model_handle,objs_info)
        model_index = model_handle_info(model_handle)
        model_index[:id_mappings] = model_index[:id_mappings]+objs_info.map{|x|Aux::hash_subset(x,[:id,:ancestor_id])}
      end

      def add_foreign_keys(model_handle,field_set)
        #TODO: only putting in once per model; not sure if need to treat instances differently; if not can do this alot more efficiently computing just once
        model_index = model_handle_info(model_handle)
        return nil unless model_index[:fks].empty?
        #put in foreign keys that are not special keys like ancestor or assembly_id
        fk_cols = field_set.foreign_key_cols() - ([:ancestor_id] +(ForeignKeyOmissions[model_handle[:model_name]]||[]))
        #TODO: replace with a set
        model_index[:fks] = fk_cols
      end
     private
      #TODO: this should be better aligned withj model declaration
      ForeignKeyOmissions = {
        :component => [:assembly_id],
        :node => [:assembly_id],
      }
      def model_handle_info(mh)
        @info[mh[:c]] ||= Hash.new
        @info[mh[:c]][mh[:model_name]] ||= {:id_mappings => Array.new, :fks => Array.new}
      end
    end
  end
end
