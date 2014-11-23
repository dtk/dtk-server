module DTK; class Clone
  class ChildContext < SimpleHashObject
    r8_nested_require('child_context','assembly_node')
    r8_nested_require('child_context','assembly_node_attribute')
    r8_nested_require('child_context','port_link')
    r8_nested_require('child_context','assembly_component_ref')
    r8_nested_require('child_context','assembly_component_attribute')
    def clone_copy_child_objects(clone_proc,level)
      clone_model_handle = clone_model_handle()
      field_set_to_copy = ret_field_set_to_copy()
      fk_info = clone_proc.fk_info
      fk_info.add_foreign_keys(clone_model_handle,field_set_to_copy)
      create_override_attrs = clone_proc.ret_real_columns(clone_model_handle,override_attrs)
      new_objs_info = ret_new_objs_info(field_set_to_copy,create_override_attrs)
      return if new_objs_info.empty?

      new_id_handles = clone_proc.add_new_children_objects(new_objs_info,clone_model_handle,clone_par_col,level)
      fk_info.add_id_mappings(clone_model_handle,new_objs_info)
      fk_info.add_id_handles(new_id_handles) #TODO: may be more efficient adding only id handles assciated with foreign keys

      # iterate all nested children
      opts_generate = Hash.new
      if include_list = include_list()
        opts_generate.merge!(:include_list => include_list)
      end
      self.class.generate(clone_proc,clone_model_handle,new_objs_info,override_attrs,opts_generate) do |child_context|
        child_context.clone_copy_child_objects(clone_proc,level+1)
      end
    end

    def self.generate(clone_proc,model_handle,unpruned_objs_info,recursive_override_attrs,opts={},&block)
      ret = Array.new
      opts_generate = Aux.hash_subset(opts,[:include_list])
      get_children_model_handles(model_handle,opts_generate) do |child_mh|
        child_mn = child_mh[:model_name]
        objs_info = unpruned_objs_info.reject{|r|r[:donot_clone] and r[:donot_clone].include?(child_mn)}
        next if objs_info.empty?

        override_attrs = clone_proc.ret_child_override_attrs(child_mh,recursive_override_attrs)
        parent_id_col = child_mh.parent_id_field_name()
        old_parent_rel_col = ret_old_parent_rel_col(clone_proc,child_mh)
        parent_rels = objs_info.map do |row|
          if old_par_id = row[old_parent_rel_col]
            {parent_id_col => row[:id],:old_par_id => old_par_id}
          else
            raise Error.new("Column (#{old_parent_rel_col}) not found in objs_info")
          end
        end
        child_context_hash = {
          :model_handle => child_mh, 
          :clone_par_col => parent_id_col, 
          :parent_rels => parent_rels, 
          :override_attrs => override_attrs, 
          :create_opts => {
            :duplicate_refs => :no_check, 
            :returning_sql_cols => returning_sql_cols(parent_id_col)
          },
          :parent_objs_info => objs_info
        }
        opts_x = Aux.hash_subset(opts,[:standard_child_context])
        child_context = create_from_hash(clone_proc,child_context_hash,opts_x)
        if block
          block.call(child_context)
        else
          ret << child_context
        end
      end
      ret unless block
    end

    def self.returning_sql_cols(parent_id_col)
      [:ancestor_id,parent_id_col]
    end

    def self.create_from_hash(clone_proc,hash,opts={})
      if opts[:standard_child_context]
        return new(clone_proc,hash)
      end
      unless clone_proc.cloning_assembly?()
        return new(clone_proc,hash)
      end

      model_name = Model.normalize_model(hash[:model_handle][:model_name])
      parent_model_name = Model.normalize_model(hash[:model_handle][:parent_model_name])
      klass = ret_special_child_context?(clone_proc,parent_model_name,model_name) || ChildContext
      klass.new(clone_proc,hash)
    end

   private
    #this can be over-written
    def include_list()
      nil
    end

    def self.ret_special_child_context?(clone_proc,parent_model_name,model_name)
      if match = (SpecialContext[clone_proc.clone_direction()][parent_model_name]||{})[model_name]
        if match.kind_of?(Proc) 
          match.call(clone_proc)
        else
          match
        end
      end
    end
    # index are clone_direction, parent, child
    SpecialContext = {
      :library_to_target => {
        :target => {
          :node => AssemblyNode, 
          :port_link => PortLink
        },
        :node => {
          :attribute => AssemblyNodeAttribute, 
          :component_ref => AssemblyComponentRef
        },
        # TODO: will put below back in after sort out issues on https://reactor8.atlassian.net/wiki/display/DTK/Component+Resource+matching
        #          :node => {:component_ref => lambda{|proc| proc.service_add_on_proc?() ? AssemblyComponentRef::AddOn : AssemblyComponentRef}},
        :component => {
          :attribute => AssemblyComponentAttribute
        }
      },
      # TODO: remove; since using different mechanism to save an assembly instance in the library
      :target_to_library => {
        #:library => {:node => AssemblyTemplateNode},
        #:node => {:component => AssemblyTemplateComponent}
      }
    }

    def initialize(clone_proc,hash)
      super(hash)
      @clone_proc = clone_proc
    end

    def db()
      @clone_proc.db()
    end

    def self.get_children_model_handles(model_handle,opts={},&block)
      include_list = opts[:include_list]
      model_handle.get_children_model_handles(:clone_context => true).each do |child_mh|
        if include_list
          next if not include_list.include?(child_mh[:model_name])
        end
        block.call(child_mh)
      end
    end

    def ret_field_set_to_copy()
      Model::FieldSet.all_real(clone_model_handle[:model_name]).with_removed_cols(:id,:local_id)
    end

    def ret_new_objs_info(field_set_to_copy,create_override_attrs)
      ancestor_rel_ds = SQL::ArrayDataset.create(db(),parent_rels,model_handle.createMH(:target))

      # all parent_rels will have same cols so taking a sample
      remove_cols = [:ancestor_id] + parent_rels.first.keys.reject{|col|col == :old_par_id}
      field_set_from_ancestor = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols({:id => :ancestor_id},{clone_par_col => :old_par_id})

      wc = nil
      ds = Model.get_objects_just_dataset(model_handle,wc,Model::FieldSet.opt(field_set_from_ancestor))
        
      select_ds = ancestor_rel_ds.join_table(:inner,ds,[:old_par_id])
      Model.create_from_select(model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
    end

    def self.ret_old_parent_rel_col(clone_proc,model_handle)
      ret = :ancestor_id
      unless clone_proc.cloning_assembly? and clone_proc.clone_direction() == :library_to_target
        return ret
      end

      model_name = Model.normalize_model(model_handle[:model_name])
      parent_model_name = Model.normalize_model(model_handle[:parent_model_name])
      if parent_model_name == :node and not [:component_ref,:port].include?(model_name)
        :node_template_id
      else
        ret
      end
    end

    def parent_rels()
      self[:parent_rels]
    end
    def model_handle()
      self[:model_handle]
    end

    # can differ such as for component_ref
    # can be over written
    def clone_model_handle()
      model_handle()
    end
    def clone_par_col()
      self[:clone_par_col]
    end
    def override_attrs()
      self[:override_attrs]
    end
    def create_opts()
      self[:create_opts]
    end
    def matches()
      self[:matches]
    end
    def parent_objs_info()
      self[:parent_objs_info]
    end
  end
end; end

