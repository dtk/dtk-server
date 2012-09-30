module XYZ
  class ChildContext < SimpleHashObject
    def clone_copy_child_objects(clone_proc,level)
      clone_model_handle = clone_model_handle()
      field_set_to_copy = ret_field_set_to_copy()
      fk_info = clone_proc.fk_info
      fk_info.add_foreign_keys(clone_model_handle,field_set_to_copy)
      create_override_attrs = clone_proc.ret_real_columns(clone_model_handle,override_attrs)
      new_objs_info = ret_new_objs_info(clone_proc.db,field_set_to_copy,create_override_attrs)
      return if new_objs_info.empty?

      new_id_handles = clone_proc.add_new_children_objects(new_objs_info,clone_model_handle,clone_par_col,level)
      fk_info.add_id_mappings(clone_model_handle,new_objs_info)
      fk_info.add_id_handles(new_id_handles) #TODO: may be more efficient adding only id handles assciated with foreign keys
      #iterate all nested children
      self.class.generate(clone_proc,clone_model_handle,new_objs_info,override_attrs) do |child_context|
        child_context.clone_copy_child_objects(clone_proc,level+1)
      end
    end

    def self.generate(clone_proc,model_handle,objs_info,recursive_override_attrs,omit_list=[],&block)
      ret = Array.new
      get_children_model_handles(model_handle,omit_list) do |child_mh|
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
        create_opts = {:duplicate_refs => :no_check, :returning_sql_cols => returning_sql_cols(parent_id_col)}
        child_context = create_from_hash(clone_proc,{:model_handle => child_mh, :clone_par_col => parent_id_col, :parent_rels => parent_rels, :override_attrs => override_attrs, :create_opts => create_opts, :parent_objs_info => objs_info})
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

    def self.create_from_hash(clone_proc,hash)
      unless clone_proc.cloning_assembly?()
        return new(clone_proc,hash)
      end

      model_name = Model.normalize_model(hash[:model_handle][:model_name])
      parent_model_name = Model.normalize_model(hash[:model_handle][:parent_model_name])
#TODO: think this is wrong since calls AssemblyNode in middle of run      
#klass = (SpecialContext[clone_proc.clone_direction()][parent_model_name]||{})[model_name] || self
      klass = (SpecialContext[clone_proc.clone_direction()][parent_model_name]||{})[model_name] || ChildContext
      klass.new(clone_proc,hash)
    end

   private
    def initialize(clone_proc,hash)
      super(hash)
      @clone_proc = clone_proc
    end

    def self.get_children_model_handles(model_handle,omit_list=[],&block)
      model_handle.get_children_model_handles(:clone_context => true).each do |child_mh|
        next if omit_list.include?(child_mh[:model_name])
        block.call(child_mh)
      end
    end

    def ret_field_set_to_copy()
      Model::FieldSet.all_real(clone_model_handle[:model_name]).with_removed_cols(:id,:local_id)
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

    #can diffeer such as for component_ref
    #can be over written
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


    class AssemblyNode < ChildContext
     private
      def initialize(clone_proc,hash)
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
        ret.each{|r|r[:node_template_id] = (mapping_rows.find{|mr|mr[:display_name] == r[:display_name]}||{})[:node_template_id]}
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
      def initialize(clone_proc,hash)
        super
        find_component_templates_in_assembly!()
      end
      def clone_model_handle()
        model_handle().createMH(:component)
      end

      def find_component_templates_in_assembly!()
        #find the component templates that each component ref is pointing to
        node_stub_ids = parent_rels.map{|pr|pr[:old_par_id]}
        sp_hash = {
          :cols => [:id,:display_name,:node_with_assembly_id,:component_template_id],
          :filter => [:oneof, :node_node_id, node_stub_ids]
        }
        matches = Model.get_objs(model_handle.createMH(:component_ref),sp_hash)
        merge!(:matches => matches)
      end

      #for processing component refs in an assembly
      def ret_new_objs_info(db,field_set_to_copy,create_override_attrs)
        #mapping from component ref to component template 
        component_mh = model_handle.createMH(:component)
        ndx_node_stub_to_instance = parent_rels.inject(Hash.new){|h,r|h.merge(r[:old_par_id] => r[:node_node_id])}
        ndx_node_template_to_ref = Hash.new

        #use workspace components, rather than lib components
        lib_cmps = matches.map{|m|component_mh.createIDH(:id => m[:component_template_id]).create_object()}
        ndx_workspace_templates = Component.create_ndx_workspace_component_templates?(lib_cmps,@clone_proc.project)
pp ndx_workspace_templates

        mapping_rows = matches.map do |m|
          node = m[:node]
          old_par_id = node[:id]
          unless node_node_id = (parent_rels.find{|r|r[:old_par_id] == old_par_id}||{})[:node_node_id]
            raise Error.new("Cannot find old_par_id #{old_par_id.to_s} in parent_rels") 
          end
         
          #set  ndx_node_template_to_ref
          #first index is the associated node instance, second is teh component template
          pntr = ndx_node_template_to_ref[ndx_node_stub_to_instance[old_par_id]] ||= Hash.new 
          pntr[m[:component_template_id]] = m[:id]

          {:ancestor_id => m[:component_template_id],
            :component_template_id => m[:component_template_id],
            :node_node_id =>  node_node_id,
            :assembly_id => node[:assembly_id]
          }
        end

        mapping_ds = SQL::ArrayDataset.create(db,mapping_rows,model_handle.createMH(:mapping))
      
        #all parent_rels will have same cols so taking a sample
        remove_cols = [:ancestor_id,:assembly_id] + parent_rels.first.keys
        cmp_template_fs = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols({:id => :component_template_id})
        cmp_template_wc = nil
        cmp_template_ds = Model.get_objects_just_dataset(component_mh,cmp_template_wc,Model::FieldSet.opt(cmp_template_fs))

        select_ds = cmp_template_ds.join_table(:inner,mapping_ds,[:component_template_id])
        ret = Model.create_from_select(component_mh,field_set_to_copy,select_ds,create_override_attrs,create_opts)
        ret.each do |r|
          component_ref_id = ndx_node_template_to_ref[r[:node_node_id]][r[:ancestor_id]]
          raise Error.new("Variable component_ref_id shoudl not be null") if component_ref_id.nil?
          r.merge!(:component_ref_id => component_ref_id, :component_template_id => r[:ancestor_id])
        end 
        ret
      end
    end
    class AssemblyComponentAttribute < ChildContext
      private
      def initialize(clone_proc,hash)
        super
      end
      def ret_new_objs_info(db,field_set_to_copy,create_override_attrs)
        new_objs_info = super
        return new_objs_info if new_objs_info.empty?
        process_attribute_overrides(db,new_objs_info)
        new_objs_info
      end

      def process_attribute_overrides(db,new_objs_info)
        #TODO: may see if can do more efficiently using attribute_override col assembly_template_id
        #parent_objs_info has component info keys: :component_template_id, :component_ref_id and (which is the new component instance)

        attr_override_fs = Model::FieldSet.new(:attribute_override,[:display_name,:component_ref_id,{:attribute_value => :value_asserted}])
        attr_override_wc = nil
        attr_override_ds = Model.get_objects_just_dataset(model_handle.createMH(:attribute_override),attr_override_wc,Model::FieldSet.opt(attr_override_fs))

        cmp_mapping_rows = parent_objs_info.map{|r|Aux::hash_subset(r,[:component_ref_id,{:id => :component_component_id}])}
        cmp_mapping_ds = SQL::ArrayDataset.create(db,cmp_mapping_rows,model_handle.createMH(:cmp_mapping))

        attr_mapping_rows = new_objs_info.map{|r|Aux::hash_subset(r,[:component_component_id,:display_name,:id])}
        attr_mapping_ds = SQL::ArrayDataset.create(db,attr_mapping_rows,model_handle.createMH(:attr_mapping))

        select_ds = attr_override_ds.join_table(:inner,cmp_mapping_ds,[:component_ref_id]).join_table(:inner,attr_mapping_ds,[:component_component_id,:display_name])
        update_set_fs = Model::FieldSet.new(:attribute,[:value_asserted])
        Model.update_from_select(model_handle.createMH(:attribute),update_set_fs,select_ds,:constant_set_values => {:is_instance_value => true})
      end
    end

    #index are clone_direction, parent, child
    SpecialContext = {
      :library_to_target => {
        :target => {:node => AssemblyNode},
        :node => {:component_ref => AssemblyComponentRef},
        :component => {:attribute => AssemblyComponentAttribute}
      },
      #TODO: remove
      :target_to_library => {
        #:library => {:node => AssemblyTemplateNode},
        #:node => {:component => AssemblyTemplateComponent}
      }
    }
  end
end
