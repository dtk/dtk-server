module DTK; class Node; class TargetRef
  class Input
    class InventoryData < self
      r8_nested_require('inventory_data','element')

      def initialize(inventory_data_hash)
        super()
        inventory_data_hash.each{|ref,hash| self << Element.new(ref,hash)}
      end

      def create_nodes_from_inventory_data(target)
        target_ref_hash = target_ref_hash()
        target_idh = target.id_handle()
        Model.import_objects_from_hash(target_idh, {node: target_ref_hash}, return_info: true)
      end

      def self.pbuilderid?(node_external_ref)
        node_external_ref ||= {}
        if host_address = node_external_ref[:routable_host_address]||node_external_ref['routable_host_address']
          "#{TargetRef.physical_node_prefix()}#{host_address}"
        end
      end

      private

      def target_ref_hash
        inject({}){|h,el|h.merge(el.target_ref_hash())}
      end
    end
  end
end; end; end


