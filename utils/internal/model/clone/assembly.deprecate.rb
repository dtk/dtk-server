module XYZ
  module CloneAssemblyInstanceMixins
    def clone_into_library_assembly(assembly_idh,id_handles)
      opts = {:include_children => true}
      proc = CloneCopyProcessor.new(assembly_idh.create_object(),opts)
      proc.add_id_handle(assembly_idh)

      #group id handles by model type
      ndx_id_handle_groups = Hash.new
      id_handles.each do |idh|
        model_name = idh[:model_name]
        (ndx_id_handle_groups[model_name] ||= Array.new) << idh
      end

      assembly_id_assign = {:assembly_id => assembly_idh.get_id()}
      overrides = assembly_id_assign.merge(:component => assembly_id_assign)
      ndx_id_handle_groups.each_value do |child_id_handles|
        child_context = proc.ret_child_context(child_id_handles,id_handle(),overrides)
        proc.clone_copy_child_objects(child_context)
      end

      proc.shift_foregn_keys()
      #TODO: check if clone_post copy needs to be done after key shift; if not can simplify
      clone_copy_output = proc.output
      clone_post_copy_hook(clone_copy_output)

      assembly_idh.get_id()
    end
  end
  module CloneChildContextAssemblyNode
    class ChildContext < SimpleHashObject
    end
    class ChildContextAssemblyNode < ChildContext
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
        Model.create_from_select(model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
      end

      private
      def matches()
        self[:matches]
      end
    end
  end

  module CloneCopyProcessorAssemblyGlobals
    AssemblyChildren = [:node,:attribute_link,:port_link]
  end
  module CloneCopyProcessorAssembly
    include CloneCopyProcessorAssemblyGlobals
    def get_nested_objects__assembly(model_handle,target_parent_mh,assembly_objs_info,recursive_override_attrs,opts)
      raise Error.new("Not treating assembly_objs_info with more than 1 element") unless assembly_objs_info.size == 1
      assembly_obj_info = assembly_objs_info.first
      ancestor_id = assembly_obj_info[:ancestor_id]
      target_parent_mn = target_parent_mh[:model_name]
      model_name = model_handle[:model_name]
      new_assembly_assign = {:assembly_id => assembly_obj_info[:id]}
      new_par_assign = {DB.parent_field(target_parent_mn,model_name) => assembly_obj_info[:parent_id]}
      AssemblyChildren.map do |nested_model_name|
        nested_mh = model_handle.createMH(:model_name => nested_model_name, :parent_model_name => target_parent_mn)
        override_attrs = new_assembly_assign.merge(ret_child_override_attrs(nested_mh,recursive_override_attrs))
        create_opts = {:duplicate_refs => :allow, :returning_sql_cols => [:ancestor_id,:assembly_id]}
        
        #putting in nulls to null-out; more efficient to omit this columns in create
        parent_rel = (DB_REL_DEF[nested_model_name][:many_to_one]||[]).inject({:old_par_id => ancestor_id}) do |hash,pos_par|
          hash.merge(matching_models?(pos_par,target_parent_mn) ? new_par_assign : {DB.parent_field(pos_par,model_name) => SQL::ColRef.null_id})
        end
        child_context_class = (matching_models?(nested_model_name,:node) and R8::Config[:use_node_bindings]) ? ChildContextAssemblyNode : ChildContext
        child = child_context_class.create(:model_handle => nested_mh, :clone_par_col => :assembly_id, :parent_rels => [parent_rel], :override_attrs => override_attrs, :create_opts => create_opts)
        if matching_models?(nested_model_name,:node) 
          unless (child[:override_attrs][:component]||{})[:assembly_id]
            child[:override_attrs].merge!(:component => new_assembly_assign)
          end

          if child.kind_of?(ChildContextAssemblyNode)
            assembly_template_idh = model_handle.createIDH(:model_name => :component, :id => ancestor_id)
            target_idh = target_parent_mh.createIDH(:id => assembly_obj_info[:parent_id])
            child.find_node_templates_in_assembly!(target_idh,assembly_template_idh)
          end
        end
        child 
      end
    end
  end
end
