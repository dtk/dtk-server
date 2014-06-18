module DTK
  class Node
    # This refers to an object that is used to point to an existing node in a target; it is a peer of Node::Template
    class TargetRef < self
      class InventoryData < Array
        def initialize(inventory_data_hash)
          super()
          inventory_data_hash.each{|ref,hash| self << Element.new(ref,hash)}
        end
      end

      def self.create_nodes_from_inventory_data(target, inventory_data)
        inventory_data_hash = ret_inventory_data_hash(inventory_data)
        target_idh = target.id_handle()
        import_objects_from_hash(target_idh, {:node => inventory_data_hash}, :return_info => true)
      end

      #these are nodes without any assembly on them
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

        ndx_matched_target_refs = ndx_target_refs_matching_instances(ret_unpruned.map{|r|r.id_handle})
        if ndx_matched_target_refs.empty?
          return ret_unpruned
        end
        ret_unpruned.reject{|r|ndx_matched_target_refs[r[:id]]}
      end

      #This creates if needed target refs and links nodes to them
      #TODO: now creating new ones as opposed to case where overlaying asssembly on existing nodes
      def self.create_linked_target_refs?(target,nodes)
        #returns new idhs indexed by node (id) they linked to
        ret = Hash.new
        num_target_refs_needed(target,nodes).each do |node_info|
          node = node_info[:node]
          num_needed = node_info[:num_needed]
          num_linked = node_info[:num_linked]
          new_target_refs = create_linked_nodes(target,node,num_needed,num_linked)
          ret[node[:id]] = new_target_refs
        end
        pp [:debug_create_linked_target_refs,ret]
raise ErrorUsage.new('got here')
      end

      def self.create_linked_nodes(target,node,num_needed,num_linked)
        target_id = target.id
        base_display_name = node.get_field?(:disply_name)
        base_ref = node.get_field?(:ref)
        create_rows = (num_linked+1..num_linked+num_needed).map do |index|
          {
            :ref => "#{base_ref}--#{index}",
            :display_name => "#{base_display_name}--#{index}",
            :managed => true,
            :datacenter_datacenter_id => target_id,
            #TODO: stub for garbage collection
            :type => 'garb'
         }
        end

        #for create model handle needs parent
        node_mh = target.model_handle().create_childMH(:node) 
#        new_target_refs = create_from_rows(attr_link_mh,new_link_rows)
pp [:debug_creating,create_rows]
      end

     private      
      #returns for each node that needs one or more target refs the following hash
      # :node
      # :num_needed
      # :num_linked
      def self.num_target_refs_needed(target,nodes)
        ret = Array.new
        #TODO: temporary; removes all nodes that are not node groups
        nodes = nodes.select{|n|n.is_node_group?()}
        return ret if nodes.empty?
        ndx_linked_target_ref_idhs = ndx_linked_target_ref_idhs(target,nodes)
        nodes.each do |node|
          node_id = node[:id]
          num_linked = (ndx_linked_target_ref_idhs[node_id]||[]).size 
          num_needed = node.attribute.cardinality - num_linked
          if num_needed > 0
            ret << {:node => node,:num_needed => num_needed,:num_linked => num_linked}
          else num_needed < 0
            Log.error("Unexpected that number of target refs (#{num_linked}) for (#{node[:display_name].to_s}) is graeter than cardinaility (#{node.attribute.cardinality.to_s})")
          end
        end
        ret
      end

      #indexed by node id
      def self.ndx_linked_target_ref_idhs(target,nodes)
        ret = Hash.new
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:node_id,:node_group_id],
          :filter => [:and, 
                      [:oneof,:node_group_id,nodes.map{|n|n.id}],
                      [:eq,:datacenter_datacenter_id,target.id]]
        }
        node_mh = target.model_handle(:node)
        get_objs(target.model_handle(:node_group_relation),sp_hash).each do |r|
          (ret[r[:node_group_id]] ||= Array.new) << node_mh.createIDH(:id => r[:node_id])
        end
      end

      #returns hash of form {TargetRefId => [matching_node_insatnce1,,],}
      def self.ndx_target_refs_matching_instances(node_target_ref_idhs)
        ret = Hash.new
        return ret if node_target_ref_idhs.empty?
        
      # object model structure that relates instance to target refs is where instance's :canonical_template_node_id field point to target_ref
        sp_hash = {
          :cols => [:id, :display_name,:canonical_template_node_id],
          :filter => [:oneof,:canonical_template_node_id,node_target_ref_idhs.map{|idh|idh.get_id()}]
        }
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

      class InventoryData
        #TODO: this is just temp until move from client formating data; right now hash is of form
        # {"physical--install-agent1"=>
        #  {"display_name"=>"install-agent1",
        #   "os_type"=>"ubuntu",
        # "managed"=>"false",
        # "external_ref"=>
        class Element < Hash
          attr_reader :type
          def initialize(ref,hash)
            super()
            if ref =~ /^physical--/
              replace(hash)
              @type = :physical
            else
              raise Error.new("Unexpected ref for inventory data ref: #{ref}")
            end
          end
        end
      end
      def self.ret_inventory_data_hash(inventory_data)
        inventory_data.inject(Hash.new){|h,el|h.merge(ret_inventory_data_hash_el(el))}
      end

      def self.ret_inventory_data_hash_el(inventory_data_el)
        el = inventory_data_el #just for succinctness
        unless name = el['name']||el['display_name']
          raise Error.new("Unexpected that that element (#{el.inspect}) has no name field")
        end
        ret_hash = el.merge('display_name' => ret_display_name(el.type,name))

        external_ref = el['external_ref']||{}
        # for type use type from external_ref ('physical'), if not then use default type()
        ret_hash.merge!(:type => external_ref['type']||type())

        host_address = nil
        if el.type == :physical
          unless host_address = external_ref['routable_host_address']
            raise Error.new("Missing field input_node_hash['external_ref']['routable_host_address']")
          end
        end
        params = {"host_address" => host_address}
        ret_hash.merge!(child_objects(params))
        ref = ret_ref(el.type,name)
        {ref => ret_hash}
      end

      def self.ret_ref(type,name)
        case type
          when :physical then "physical--#{name}"
          else raise Error.new("Unexpected type (#{type})")
        end
      end
      def self.ret_display_name(type,name,opts={})
        case type
          when :physical then "physical--#{name}"
          else raise Error.new("Unexpected type (#{type})")
        end
      end


      #TODO: collapse with application/utility/library_nodes - node_info
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
