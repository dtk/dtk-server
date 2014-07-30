module DTK
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      r8_nested_require('target_ref','input')

      def is_target_ref?()
        true
      end
      def self.types()
        Types
      end
      Types = [Type::Node.target_ref,Type::Node.target_ref_staged]

      def self.print_form(display_name)
        if display_name =~ Regexp.new("^#{PhysicalNodePrefix}(.+$)")
          $1
        else
          split = display_name.split(AssemblyDelim)
          unless split.size == 2
            Log.error("Display Name has unexpected form (#{display_name})")
            return display_name
          end
          split[1]
        end
      end

      def self.ret_display_name(type,target_ref_name,opts={})
        case type
          when :physical
            "#{PhysicalNodePrefix}#{name}"
          when :base_node_link
            ret = "#{opts[:assembly_name]}#{AssemblyDelim}#{target_ref_name}"
            if index = opts[:index]
              ret << "#{IndexDelim}#{index.to_s}"
            end
            ret
          else
            raise Error.new("Unexpected type (#{type})")
        end
      end
      AssemblyDelim = '::'
      IndexDelim = ':'
      PhysicalNodePrefix = 'physical--'

      # returns hash of form {node_id => NodeWithTargetRefs,..}
      NodeWithTargetRefs = Struct.new(:node,:target_refs)
      def self.get_ndx_linked_target_refs(node_mh,node_ids)
        ret = Hash.new
        return ret if node_ids.empty?
        sp_hash = {
          :cols => [:id,:display_name,:type,:linked_target_refs],
          :filter => [:oneof, :id, node_ids]
        }
        get_objs(node_mh,sp_hash).each do |n|
          n.delete(:node_group_relation)
          target_ref = n.delete(:target_ref)
          pntr = ret[n[:id]] ||= NodeWithTargetRefs.new(n,Array.new)
          pntr.target_refs << target_ref if target_ref
        end
        ret
      end

      AnnotatedNodes = Struct.new(:to_link,:to_create)
      def self.create_target_refs_and_links?(target,assembly,annotated_nodes,opts={})
        unless annotated_nodes.to_create.empty?
          Input::BaseNodes.create_linked_target_refs?(target,assembly,annotated_nodes.to_create)
        end
        unless annotated_nodes.to_link.empty?
          if opts[:do_not_check_link_exists]
            Input::BaseNodes.link_to_target_refs(target,annotated_nodes.to_link)
          else
            raise Error.new("Not support: create_target_refs_and_links? w/o {:do_not_check_link_exists => true}")
          end
        end
      end

      # these are nodes without any assembly on them
      def self.get_free_nodes(target)
        sp_hash = {
          :cols => [:id, :display_name, :ref, :type, :assembly_id, :datacenter_datacenter_id, :managed],
          :filter => [:and,
                        [:eq, :type, Type::Node.target_ref],
                        [:eq, :datacenter_datacenter_id, target[:id]],
                        [:eq, :managed, true]]
        }
        node_mh = target.model_handle(:node)
        ret_unpruned = get_objs(node_mh,sp_hash,:keep_ref_cols => true)

        ndx_matched_target_refs = ndx_target_refs_to_their_instances(ret_unpruned.map{|r|r.id_handle})
        if ndx_matched_target_refs.empty?
          return ret_unpruned
        end
        ret_unpruned.reject{|r|ndx_matched_target_refs[r[:id]]}
      end

      def self.create_nodes_from_inventory_data(target, inventory_data)
        Input.create_nodes_from_inventory_data(target, inventory_data)
      end

      class Info
        attr_reader :target_ref,:ref_count
        def initialize(target_ref)
          @target_ref = target_ref
          @ref_count = 0
        end
        def increase_ref_count()
          @ref_count +=1 
        end
      end
      def self.get_linked_target_ref_info_single_node(node_instance)
        info_array = get_linked_target_refs_info(node_instance)
        if info_array.size > 1
          raise Error.new("Unexpected that a (non group) node instance is linked to more than one target ref")
        end
        info_array.first||Info.new(nil)
      end
      def self.get_linked_target_refs_info(node_instance)
        get_ndx_linked_target_refs_info([node_instance]).values.first||[]
      end
      def self.get_ndx_linked_target_refs_info(node_instances)
        ret = Hash.new
        if node_instances.empty?
          return ret
        end
        sp_hash = {
          :cols => [:node_group_id,:target_refs_with_links],
          :filter => [:oneof,:node_group_id,node_instances.map{|n|n[:id]}]
        }
        ndx_ret = Hash.new
        ngr_mh = node_instances.first.model_handle(:node_group_relation)
        get_objs(ngr_mh,sp_hash).each do |r|
          node_id = r[:node_group_id]
          second_ndx = r[:target_ref].id
          info = (ndx_ret[node_id] ||= Hash.new)[second_ndx] ||= Info.new(r[:target_ref])
          info.increase_ref_count()
        end
        ndx_ret.inject(Hash.new){|h,(node_id,ndx_info)|h.merge(node_id => ndx_info.values)}
      end


      # returns hash of form {NodeInstanceId -> [target_refe_idh1,...],,}
      # filter can be of form
      #  {:node_instance_idhs => [idh1,,]}, or
      #  {:node_group_relation_idhs => [idh1,,]}
      def self.ndx_matching_target_ref_idhs(filter)
        ret = Hash.new
        filter_field = sample_idh = nil
        if filter[:node_instance_idhs]
          idhs = filter[:node_instance_idhs]
          filter_field = :node_group_id
        elsif filter[:node_group_relation_idhs]
          idhs = filter[:node_group_relation_idhs]
          filter_field = :id
        else
          raise Error.new("Unexpected filter: #{filter.inspect}")
        end
        if idhs.empty?
          return ret
        end

        #node_group_id matches on instance side and node_id on target ref side
        sp_hash = {
          :cols => [:node_id,:node_group_id],
          :filter => [:oneof,filter_field,idhs.map{|n|n.get_id}]
        }
        sample_idh = idhs.first
        target_ref_mh = sample_idh.createMH(:node)
        ngr_mh = sample_idh.createMH(:node_group_relation)
        Model.get_objs(ngr_mh,sp_hash).each do |r|
          node_id = r[:node_group_id]
          (ret[node_id] ||= Array.new) << target_ref_mh.createIDH(:id => r[:node_id])
        end
        ret
      end

     private

      # returns hash of form {TargetRefId => [matching_node_instance1,,],}
      def self.ndx_target_refs_to_their_instances(node_target_ref_idhs)
        ret = Hash.new
        return ret if node_target_ref_idhs.empty?
      # object model structure that relates instance to target refs is where instance's :canonical_template_node_id field point to target_ref
        sp_hash = {
          :cols => [:id, :display_name,:canonical_template_node_id],
          :filter => [:oneof,:canonical_template_node_id,node_target_ref_idhs.map{|idh|idh.get_id()}]
        }
Log.error("see why this is using :canonical_template_node_id and not node_group_relation")
        node_mh = node_target_ref_idhs.first.createMH()
        get_objs(node_mh,sp_hash).each do |r|
          (ret[r[:canonical_template_node_id]] ||= Array.new) << r
        end
        ret
      end
    end
  end
end
