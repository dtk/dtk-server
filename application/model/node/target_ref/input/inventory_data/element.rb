module DTK; class Node; class TargetRef
  class Input; class InventoryData
    #TODO: this is just temp until move from client formating data; right now hash is of form
    # {"physical--install-agent1"=>
    #  {"display_name"=>"install-agent1",
    #   "os_type"=>"ubuntu",
    # "managed"=>"false",
    # "external_ref"=>
    class Element < Hash
      def initialize(ref,hash)
        super()
        if ref =~ Regexp.new("^#{TargetRef.physical_node_prefix()}")
          replace(hash)
          @type = :physical
        else
          raise Error.new("Unexpected ref for inventory data ref: #{ref}")
        end
      end

      def target_ref_hash
        unless name = self['name']||self['display_name']
          raise Error.new("Unexpected that that element (#{inspect}) has no name field")
        end
        ret_hash = merge('display_name' => ret_display_name(name))

        external_ref = self['external_ref']||{}
        ret_hash.merge!(type: external_ref['type']||Type::Node.target_ref)

        host_address = nil
        if @type == :physical
          unless host_address = external_ref['routable_host_address']
            raise Error.new("Missing field input_node_hash['external_ref']['routable_host_address']")
          end
        end
        params = {'host_address' => host_address}
        ret_hash.merge!(Input.child_objects(params))
        {ret_ref(name) => ret_hash}
      end

      private

      def ret_display_name(name)
        TargetRef.ret_display_name(@type,name)
      end

      def ret_ref(name)
        "#{@type}--#{name}"
      end
    end
  end; end
end; end; end
