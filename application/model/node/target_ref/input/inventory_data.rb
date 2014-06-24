module DTK; class Node; class TargetRef
  class Input 
    class InventoryData < self
      def initialize(inventory_data_hash)
        super()
        inventory_data_hash.each{|ref,hash| self << Element.new(ref,hash)}
      end

      def ret_target_ref_hash()
        inject(Hash.new){|h,el|h.merge(el.ret_target_ref_hash())}
      end
      
      #TODO: this is just temp until move from client formating data; right now hash is of form
      # {"physical--install-agent1"=>
      #  {"display_name"=>"install-agent1",
      #   "os_type"=>"ubuntu",
      # "managed"=>"false",
      # "external_ref"=>
      class Element < Hash
        include ElementMixin
        def initialize(ref,hash)
          super()
          if ref =~ /^physical--/
            replace(hash)
            @type = :physical
          else
            raise Error.new("Unexpected ref for inventory data ref: #{ref}")
          end
        end
        
        def ret_target_ref_hash()
          unless name = self['name']||self['display_name']
            raise Error.new("Unexpected that that element (#{inspect}) has no name field")
          end
          ret_hash = merge('display_name' => ret_display_name(name))
          
          external_ref = self['external_ref']||{}
          ret_hash.merge!(:type => external_ref['type']||TargetRef.type())
          
          host_address = nil
          if @type == :physical
            unless host_address = external_ref['routable_host_address']
              raise Error.new("Missing field input_node_hash['external_ref']['routable_host_address']")
            end
          end
          params = {"host_address" => host_address}
          ret_hash.merge!(Input.child_objects(params))
          {ret_ref(name) => ret_hash}
        end
      end
    end
  end
end; end; end


