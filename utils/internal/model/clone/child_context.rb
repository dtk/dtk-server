module XYZ
  class ChildContext < SimpleHashObject
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
    private
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

    class AssemblyNode < ChildContext
      #for processing node stubs in an assembly
      def ret_new_objs_info(db,field_set_to_copy,create_override_attrs)
        ancestor_rel_ds = SQL::ArrayDataset.create(db,parent_rels,model_handle.createMH(:target))
      
        #all parent_rels will have same cols so taking a sample
        remove_cols = [:ancestor_id,:display_name,:type] + parent_rels.first.keys
        node_template_fs = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols(:id => :node_template_id)
        node_template_wc = nil
        node_template_ds = Model.get_objects_just_dataset(model_handle,node_template_wc,Model::FieldSet.opt(node_template_fs))

        #mapping from node stub to node template and overriding appropriate node template columns
        mapping_rows = matches.map{|m|{:type => "staged",:ancestor_id => m[:node_stub_idh].get_id(),:node_template_id => m[:node_template_idh].get_id(), :display_name => m[:node_stub_display_name]}}
        mapping_ds = SQL::ArrayDataset.create(db,mapping_rows,model_handle.createMH(:mapping))
        
        select_ds = ancestor_rel_ds.join_table(:inner,node_template_ds).join_table(:inner,mapping_ds,[:node_template_id])
        ret = Model.create_from_select(model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
        ret.each do |r|
          r.merge!(:node_template_id => (mapping_rows.find{|mr|mr[:assembly_id] = r[:assembly_id]}||{})[:node_template_id])
        end
        ret
      end
    
      private
      def initialize(hash)
        super
        assembly_template_idh = model_handle.createIDH(:model_name => :component, :id => hash[:ancestor_id])
        find_node_templates_in_assembly!(hash[:target_idh],assembly_template_idh)
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
      
      def matches()
        self[:matches]
      end
    end
    class AssemblyComponentRef < ChildContext
      def initialize(hash)
        super
      end
    end

    #index is parent and child
    SpecialContext = {
      :target => {:node => AssemblyNode},
      :node => {:component_ref => AssemblyComponentRef}
    }
  end
end
