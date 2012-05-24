module XYZ
  class ChildContext < SimpleHashObject
    def self.get_from_parent_relation(clone_proc,model_handle,objs_info,recursive_override_attrs,omit_list=[])
      ret = Array.new
      model_handle.get_children_model_handles(:clone_context => true).each do |child_mh|
        next if omit_list.include?(child_mh[:model_name])
        override_attrs = clone_proc.ret_child_override_attrs(child_mh,recursive_override_attrs)
        parent_id_col = child_mh.parent_id_field_name()
        old_parent_rel_col = ret_old_parent_rel_col(clone_proc,child_mh)
        parent_rels = objs_info.map do |row|
          if old_par_id = row[old_parent_rel_col]
            {parent_id_col => row[:id],:old_par_id => old_par_id}
          else
            raise Error.new("Column (#{parent_rel_col}) not found in objs_info")
          end
        end
        create_opts = {:duplicate_refs => :no_check, :returning_sql_cols => [:ancestor_id,parent_id_col]}
        ret << create(clone_proc,{:model_handle => child_mh, :clone_par_col => parent_id_col, :parent_rels => parent_rels, :override_attrs => override_attrs, :create_opts => create_opts})
      end
      ret
    end

    def self.create(clone_proc,hash)
      unless clone_proc.kind_of?(Model::CloneCopyProcessorAssembly)
        return new(hash)
      end

      unless R8::Config[:use_node_bindings]
        return new(hash)
      end

      model_name = Model.normalize_model(hash[:model_handle][:model_name])
      parent_model_name = Model.normalize_model(hash[:model_handle][:parent_model_name])
      klass = (SpecialContext[parent_model_name]||{})[model_name] || self
      klass.new(hash)
    end

    def create_new_objects(clone_proc)
      field_set_to_copy = Model::FieldSet.all_real(model_handle[:model_name]).with_removed_cols(:id,:local_id)
      clone_proc.fk_info.add_foreign_keys(model_handle,field_set_to_copy)
      create_override_attrs = clone_proc.ret_real_columns(model_handle,override_attrs)
      ret_new_objs_info(clone_proc.db,field_set_to_copy,create_override_attrs)
    end

   private
    def ret_field_set_to_copy()
      Model::FieldSet.all_real(model_handle[:model_name]).with_removed_cols(:id,:local_id)
    end

    def ret_new_objs_info(db,field_set_to_copy,create_override_attrs)
      ancestor_rel_ds = SQL::ArrayDataset.create(db,parent_rels,model_handle.createMH(:target))

      #all parent_rels will have same cols so taking a sample
      remove_cols = [:ancestor_id] + parent_rels.first.keys.reject{|col|col == :old_par_id}
      field_set_from_ancestor = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols({:id => :ancestor_id},{clone_par_col => :old_par_id})

      wc = nil
      ds = Model.get_objects_just_dataset(model_handle,wc,Model::FieldSet.opt(field_set_from_ancestor))
        
      select_ds = ancestor_rel_ds.join_table(:inner,ds,[:old_par_id])
      Model.create_from_select(model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
    end

    def self.ret_old_parent_rel_col(clone_proc,model_handle)
      ret = :ancestor_id
      unless clone_proc.kind_of?(Model::CloneCopyProcessorAssembly)
        return ret
      end

      unless R8::Config[:use_node_bindings]
        return ret
      end
      model_name = Model.normalize_model(model_handle[:model_name])
      parent_model_name = Model.normalize_model(model_handle[:parent_model_name])
      if parent_model_name == :node and model_name != :component_ref
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

    class AssemblyNode < ChildContext
     private
      def initialize(hash)
        super
        assembly_template_idh = model_handle.createIDH(:model_name => :component, :id => hash[:ancestor_id])
        find_node_templates_in_assembly!(hash[:target_idh],assembly_template_idh)
      end

      #for processing node stubs in an assembly
      def ret_new_objs_info(db,field_set_to_copy,create_override_attrs)
        ancestor_rel_ds = SQL::ArrayDataset.create(db,parent_rels,model_handle.createMH(:target))
      
        #all parent_rels will have same cols so taking a sample
        remove_cols = [:ancestor_id,:display_name,:type,:ref] + parent_rels.first.keys
        node_template_fs = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols(:id => :node_template_id)
        node_template_wc = nil
        node_template_ds = Model.get_objects_just_dataset(model_handle,node_template_wc,Model::FieldSet.opt(node_template_fs))

        #mapping from node stub to node template and overriding appropriate node template columns
        mapping_rows = matches.map do |m|
          {:type => "staged",
            :ancestor_id => m[:node_stub_idh].get_id(),
            :node_template_id => m[:node_template_idh].get_id(), 
            :display_name => m[:node_stub_display_name],
            :ref => m[:node_stub_display_name]
          }
        end
        mapping_ds = SQL::ArrayDataset.create(db,mapping_rows,model_handle.createMH(:mapping))
        
        select_ds = ancestor_rel_ds.join_table(:inner,node_template_ds).join_table(:inner,mapping_ds,[:node_template_id])
        ret = Model.create_from_select(model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
        ret.each do |r|
          r.merge!(:node_template_id => (mapping_rows.find{|mr|mr[:assembly_id] = r[:assembly_id]}||{})[:node_template_id])
        end
        ret
      end
    
      def find_node_templates_in_assembly!(target_idh,assembly_template_idh)
        #find the assembly's stub nodes and then use the node binding to find the node templates
        sp_hash = {
          :cols => [:id,:display_name,:node_binding_ruleset],
          :filter => [:eq, :assembly_id, assembly_template_idh.get_id()]
        }
        node_info = Model.get_objs(assembly_template_idh.createMH(:node),sp_hash)
        target = target_idh.create_object()
        #TODO: may be more efficient to get these all at once
        matches = node_info.map do |r|
          node_template_idh = r[:node_binding_ruleset].find_matching_node_template(target).id_handle()
          {:node_stub_idh => r.id_handle, :node_stub_display_name => r[:display_name], :node_template_idh => node_template_idh}
        end
        merge!(:matches => matches)
      end
    end
    class AssemblyComponentRef < ChildContext
     private
      def initialize(hash)
        super
        find_component_templates_in_assembly!()
      end

      def ret_field_set_to_copy()
        Model::FieldSet.all_real(:component).with_removed_cols(:id,:local_id)
      end

      #for processing component refs in an assembly
      def ret_new_objs_info(db,field_set_to_copy,create_override_attrs)
        ancestor_rel_ds = SQL::ArrayDataset.create(db,parent_rels,model_handle.createMH(:target))

        #mapping from component ref to component template 
        mapping_rows = matches.map do |m|
          old_par_id = m[:node_node_id]
          unless node_node_id = parent_rels.find{|r|r[:old_par_id] == old_par_id}
            raise Error.new("Cannot find old_par_id #{old_par_id.to_s} in parent_rels") 
          end
          {:ancestor_id => m[:id],
            :component_template_id => m[:component_template_id],
            :node_node_id =>  node_node_id
          }
        end
        mapping_ds = SQL::ArrayDataset.create(db,mapping_rows,model_handle.createMH(:mapping))
      
        #all parent_rels will have same cols so taking a sample
        remove_cols = [:ancestor_id] + parent_rels.first.keys
        cmp_template_fs = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols({:id => :component_template_id})
        cmp_template_wc = nil
        cmp_template_ds = Model.get_objects_just_dataset(model_handle,cmp_template_wc,Model::FieldSet.opt(cmp_template_fs))

        select_ds = cmp_template_ds.join_table(:inner,mapping_ds,[:component_template_id])
        Model.create_from_select(model_handle.createMH(:component),field_set_to_copy,select_ds,create_override_attrs,create_opts)
      end

      def find_component_templates_in_assembly!()
        #find the component templates that each component ref is pointing to
        node_stub_ids = parent_rels.map{|pr|pr[:old_par_id]}
        sp_hash = {
          :cols => [:id,:display_name,:node_node_id,:component_template_id],
          :filter => [:oneof, :node_node_id, node_stub_ids]
        }
        matches = Model.get_objs(model_handle.createMH(:component_ref),sp_hash)
        merge!(:matches => matches)
      end
    end

    #index is parent and child
    SpecialContext = {
      :target => {:node => AssemblyNode},
      :node => {:component_ref => AssemblyComponentRef}
    }
  end
end
