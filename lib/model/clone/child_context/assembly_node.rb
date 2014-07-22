module DTK
  class ChildContext
    class AssemblyNode < self
     private
      def include_list()
        [:attribute,:attribute_link,:component,:component_ref,:node_interface,:port]
      end

      def initialize(clone_proc,hash)
        super
        assembly_template_idh = model_handle.createIDH(:model_name => :component, :id => hash[:ancestor_id])
        sao_node_bindings = clone_proc.service_add_on_node_bindings()
        target = hash[:target_idh].create_object()
        matches = 
          if target.get_field?(:iaas_type) == 'physical'
            find_node_target_ref_matches(target,assembly_template_idh)
          else
            # can either be node templates, meaning spinning up node, or
            #  a match to an existing node in which case the existing node target ref is returned 
            find_matches_for_nodes(target,assembly_template_idh,sao_node_bindings)
          end
        merge!(:matches => matches) if matches
      end

      # for processing node stubs in an assembly
      def ret_new_objs_info(field_set_to_copy,create_override_attrs)
        ret = Array.new
        ancestor_rel_ds = SQL::ArrayDataset.create(db(),parent_rels,model_handle.createMH(:target))
      
        # all parent_rels will have same cols so taking a sample
        remove_cols = [:ancestor_id,:display_name,:type,:ref,:canonical_template_node_id] + parent_rels.first.keys
        node_template_fs = field_set_to_copy.with_removed_cols(*remove_cols).with_added_cols(:id => :node_template_id)
        node_template_wc = nil
        node_template_ds = Model.get_objects_just_dataset(model_handle,node_template_wc,Model::FieldSet.opt(node_template_fs))

        target_id = parent_rels.first[:datacenter_datacenter_id]
        sp_hash = {
          :cols => [:id, :display_name, :type, :iaas_type],
          :filter => [:eq, :id, target_id]
        }
        target = Model.get_obj(model_handle.createMH(:target),sp_hash)

        # mapping from node stub to node template and overriding appropriate node template columns
        unless matches.empty?
          ndx_matches = Hash.new
          ndx_mapping_rows = matches.inject(Hash.new) do |h,m|
            display_name = m[:instance_display_name]
            ndx_matches.merge!(display_name => m)
            node_template_id = m[:node_template_idh].get_id()
            el = {
              :type => m[:instance_type],
              :ancestor_id => m[:node_stub_idh].get_id(),
              :canonical_template_node_id => node_template_id,
              :node_template_id => node_template_id,
              :display_name => display_name,
              :ref => m[:instance_ref]
            }
            h.merge(display_name => el)
          end
          mapping_ds = SQL::ArrayDataset.create(db(),ndx_mapping_rows.values,model_handle.createMH(:mapping))
          
          select_ds = ancestor_rel_ds.join_table(:inner,node_template_ds).join_table(:inner,mapping_ds,[:node_template_id])
          ret = Model.create_from_select(model_handle,field_set_to_copy,select_ds,create_override_attrs,create_opts)

          ret.each do |r|
            display_name = r[:display_name]
            r[:node_template_id] = (ndx_mapping_rows[display_name]||{})[:node_template_id]
            r[:donot_clone] = ndx_matches[display_name][:donot_clone]
          end
        end

        # add to ret rows for each service add node binding
        service_add_additions = @clone_proc.get_service_add_on_mapped_nodes(create_override_attrs,create_opts)
        unless service_add_additions.empty?
          ret += service_add_additions
        end
        ret
      end

      def find_node_target_ref_matches(target,assembly_template_idh)
        sp_hash = {
          :cols => [:id,:display_name,:group_id],
          :filter => [:eq, :assembly_id, assembly_template_idh.get_id()]
        }
        stub_nodes = Model.get_objs(assembly_template_idh.createMH(:node),sp_hash)

        free_nodes = Node::TargetRef.get_free_nodes(target)
        # assuming the free nodes are interchangable; pick one for each match
        num_free = free_nodes.size
        num_needed = stub_nodes.size
        if num_free < num_needed
          num  = (num_needed == 1 ? '1 free node is' : "#{num_needed} free nodes are")
          free = (num_free == 1 ? '1 is' : "#{num_free} are")
          raise ErrorUsage.new("Cannot stage the assembly template because #{num} needed, but just #{free} available")
        end
        ret = Array.new
        stub_nodes.each_with_index do |stub_node,i|
          node_target_ref = free_nodes[i]
          ret << hash_el_when_match(stub_node,node_target_ref)
        end
        ret
      end

      def find_matches_for_nodes(target,assembly_template_idh,sao_node_bindings=nil)
        # find the assembly's stub nodes and then use the node binding to find the node templates
        # as will as using, if non-empty, service_add_on_node_bindings to see what nodes mapping to existing ones and thus shoudl be omitted in clone
        sp_hash = {
          :cols => [:id,:display_name,:type,:node_binding_ruleset],
          :filter => [:eq, :assembly_id, assembly_template_idh.get_id()]
        }
        node_info = Model.get_objs(assembly_template_idh.createMH(:node),sp_hash)
        unless sao_node_bindings.empty?
          stubs_to_omit = sao_node_bindings.map{|r|r[:sub_assembly_node_id]}
          unless stubs_to_omit.empty?
            node_info.reject!{|n|stubs_to_omit.include?(n[:id])}
          end
        end

        node_bindings = NodeBindings.get_node_bindings(assembly_template_idh) 
        node_mh = target.model_handle(:node)
        node_info.map do |node|
          nb_ruleset = node[:node_binding_ruleset]
          node_target = node_bindings && node_bindings.has_node_target?(node)
          case match_or_create_node?(target,node,node_target,nb_ruleset)
            when :create 
              opts_fm = {:node_binding_ruleset => nb_ruleset, :node_target => node_target}
              node_template = Node::Template.find_matching_node_template(target,opts_fm)
              hash_el_when_create(node,node_template)
            when :match  
              if node_target_ref = NodeBindings.create_linked_target_ref?(target,node,node_target)
                hash_el_when_match(node,node_target_ref)
              else
                Log.error('Temp logic as default if cannot find_matching_target_ref then create')
                node_template = Node::Template.find_matching_node_template(target,:node_binding_ruleset => nb_ruleset)
                hash_el_when_create(node,node_template)
              end
            else 
             raise Error.new("Unexpected return value from match_or_create_node")
          end
        end
      end

      def match_or_create_node?(target,node,node_target,nb_ruleset)
        if nb_ruleset
          :create
        elsif node_target
          node_target.match_or_create_node?(target)
        else
          :create
        end
      end

      def hash_el_when_create(node,node_template)
        instance_type = (node.is_node_group?() ? Node::Type::NodeGroup.staged : Node::Type::Node.staged)
        {
          :instance_type         => instance_type,
          :node_stub_idh         => node.id_handle, 
          :instance_display_name => node[:display_name],
          :instance_ref          => instance_ref(node[:display_name]),
          :node_template_idh     => node_template.id_handle()
        }
      end
      def hash_el_when_match(node,node_target_ref)
        {
          :instance_type         => Node::Type::Node.instance,
          :node_stub_idh         => node.id_handle, 
          :instance_display_name => node[:display_name],
          :instance_ref          => instance_ref(node[:display_name]),
          :node_template_idh     => node_target_ref.id_handle(),
          :donot_clone           => [:attribute]
        }
      end
      
      def instance_ref(node_ref_part)
        "assembly--#{self[:assembly_obj_info][:display_name]}--#{node_ref_part}"
      end

      def cleanup_after_error()
        Model.delete_instance(model_handle.createIDH(:model_name => :component,:id => override_attrs[:assembly_id]))
      end

    end
  end
end
