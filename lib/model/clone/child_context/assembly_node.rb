module DTK
  class ChildContext
    class AssemblyNode < self
     private
      def initialize(clone_proc,hash)
        super
        assembly_template_idh = model_handle.createIDH(:model_name => :component, :id => hash[:ancestor_id])
        sao_node_bindings = clone_proc.service_add_on_node_bindings()
        find_node_templates_in_assembly!(hash[:target_idh],assembly_template_idh,sao_node_bindings)
      end

      #for processing node stubs in an assembly
      def ret_new_objs_info(field_set_to_copy,create_override_attrs)
        ret = Array.new
        ancestor_rel_ds = SQL::ArrayDataset.create(db(),parent_rels,model_handle.createMH(:target))
      
        #all parent_rels will have same cols so taking a sample
        remove_cols = [:ancestor_id,:display_name,:type,:ref] + parent_rels.first.keys
        node_template_fs = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols(:id => :node_template_id)
        node_template_wc = nil
        node_template_ds = Model.get_objects_just_dataset(model_handle,node_template_wc,Model::FieldSet.opt(node_template_fs))

        #mapping from node stub to node template and overriding appropriate node template columns
        unless matches.empty?
          mapping_rows = matches.map do |m|
            {:type => "staged",
              :ancestor_id => m[:node_stub_idh].get_id(),
              :node_template_id => m[:node_template_idh].get_id(), 
              :display_name => m[:node_stub_display_name],
              :ref => m[:node_stub_display_name]
            }
          end
          mapping_ds = SQL::ArrayDataset.create(db(),mapping_rows,model_handle.createMH(:mapping))
          
          select_ds = ancestor_rel_ds.join_table(:inner,node_template_ds).join_table(:inner,mapping_ds,[:node_template_id])
          ret = Model.create_from_select(model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)
        end
        ret.each{|r|r[:node_template_id] = (mapping_rows.find{|mr|mr[:display_name] == r[:display_name]}||{})[:node_template_id]}

        #add to ret rows for each service add node binding
        service_add_additions = @clone_proc.get_service_add_on_mapped_nodes(create_override_attrs,create_opts)
        unless service_add_additions.empty?
          ret += service_add_additions
        end
        ret
      end
    
      def find_node_templates_in_assembly!(target_idh,assembly_template_idh,service_add_on_node_bindings)
        #find the assembly's stub nodes and then use the node binding to find the node templates
        #as will as using, if non-empty, ervice_add_on_node_bindings to see what nodes mapping to existing ones and thus shoudl be omitted in clone
        sp_hash = {
          :cols => [:id,:display_name,:node_binding_ruleset],
          :filter => [:eq, :assembly_id, assembly_template_idh.get_id()]
        }
        node_info = Model.get_objs(assembly_template_idh.createMH(:node),sp_hash)
        stubs_to_omit = service_add_on_node_bindings.map{|r|r[:sub_assembly_node_id]}
        unless stubs_to_omit.empty?
          node_info.reject!{|n|stubs_to_omit.include?(n[:id])}
        end

        #TODO: see why this causes bug target = target_idh.create_object(:model_name => :target_instance)
        # No rules in the node being match the target (/home/dtk18/server/application/model/node_binding_ruleset.rb:22
        target = target_idh.create_object()
        node_mh = target_idh.createMH(:node)
        #TODO: may be more efficient to get these all at once
        matches = node_info.map do |r|
          node_template_idh = 
            if r[:node_binding_ruleset]
              r[:node_binding_ruleset].find_matching_node_template(target).id_handle()
            else
              Node::Template.null_node_template_idh(node_mh)
            end
          {:node_stub_idh => r.id_handle, :node_stub_display_name => r[:display_name], :node_template_idh => node_template_idh}
        end
        merge!(:matches => matches)
      end

      def cleanup_after_error()
        Model.delete_instance(model_handle.createIDH(:model_name => :component,:id => override_attrs[:assembly_id]))
      end
    end
  end
end
