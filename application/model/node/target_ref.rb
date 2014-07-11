module DTK
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      r8_nested_require('target_ref','input')

      # these are nodes without any assembly on them
      def self.get_free_nodes(target)
        sp_hash = {
          :cols => [:id, :display_name, :ref, :type, :assembly_id, :datacenter_datacenter_id, :managed],
          :filter => [:and,
                        [:eq, :type, type()],
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

      def self.type()
        TypeField
      end
      TypeField = 'target_ref'

      def self.process_import_node_input!(input_node_hash)
        unless host_address = input_node_hash["external_ref"]["routable_host_address"]
          raise Error.new("Missing field input_node_hash['external_ref']['routable_host_address']")
        end

        # for type use type from external_ref ('physical'), if not then use default type()
        type = input_node_hash["external_ref"]["type"] if input_node_hash["external_ref"]
        input_node_hash.merge!("type" => type||type())
        params = {"host_address" => host_address}
        input_node_hash.merge!(child_objects(params))
      end

      # TODO: collapse with application/utility/library_nodes - node_info
      def self.child_objects(params={})
        {
          "attribute"=> {
            "host_addresses_ipv4"=>{
              "required"=>false,
              "read_only"=>true,
              "is_port"=>true,
              "cannot_change"=>false,
              "data_type"=>"json",
              "value_derived"=>[params["host_address"]],
              "semantic_type_summary"=>"host_address_ipv4",
              "display_name"=>"host_addresses_ipv4",
              "dynamic"=>true,
              "hidden"=>true,
              "semantic_type"=>{":array"=>"host_address_ipv4"}
            },
            "fqdn"=>{
              "required"=>false,
              "read_only"=>true,
              "is_port"=>true,
              "cannot_change"=>false,
              "data_type"=>"string",
              "display_name"=>"fqdn",
              "dynamic"=>true,
              "hidden"=>true,
            },
            "node_components"=>{
              "required"=>false,
              "read_only"=>true,
              "is_port"=>true,
              "cannot_change"=>false,
              "data_type"=>"json",
              "display_name"=>"node_components",
              "dynamic"=>true,
              "hidden"=>true,
            }
          },
          "node_interface"=>{
            "eth0"=>{"type"=>"ethernet", "display_name"=>"eth0"}
          }
        }
      end
    end
  end
end
