module DTK
  class ServiceNodeGroup
    module IdNameHelper
      def self.check_valid_id(model_handle,id)
        check_valid_id_helper(model_handle,id,filter(id: id))
      end
      def self.name_to_id(model_handle,name)
        sp_hash =  {
          cols: [:id],
          filter: filter(display_name: name)
        }
        name_to_id_helper(model_handle,name,sp_hash)
      end
      def self.id_to_name(model_handle, id)
        sp_hash =  {
          cols: [:display_name],
          filter: filter(id: id)
        }
        rows = get_objs(model_handle,sp_hash)
        rows && rows.first[:display_name]
      end
      
      private

      def self.filter(added_condition_hash)
        FilterBase + [[:eq, added_condition_hash.keys.first,added_condition_hash.values.first]]
      end
      
      NodeType = 'service_node_group'
      FilterBase = 
        [:and,
         [:eq, :type, NodeType],
         [:neq, :datacenter_datacenter_id, nil]
        ]
    end
  end
end

