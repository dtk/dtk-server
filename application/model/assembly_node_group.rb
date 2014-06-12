module DTK
  class AssemblyNodeGroup < Node
    # create_hash has form:
    # display_name:
    # cardinality: INTEGER
    # cardinality_max: INTEGER (optional)
    # element_name: "example: slave.${index} (optional)"
    def self.create(parent_idh,create_hash)
      
    end


    def self.check_valid_id(model_handle,id)
      IdNameHelper.check_valid_id(model_handle,id)
    end
    def self.name_to_id(model_handle,name)
      IdNameHelper.name_to_id(model_handle,name)
    end
    def self.id_to_name(model_handle, id)
      IdNameHelper.id_to_name(model_handle, id)
    end
   private
    module IdNameHelper
      def self.check_valid_id(model_handle,id)
        check_valid_id_helper(model_handle,id,Filter)
      end
      def self.name_to_id(model_handle,name)
        sp_hash =  {
        :cols => [:id],
        :filter => Filter
        }
        name_to_id_helper(model_handle,name,sp_hash)
      end
      def self.id_to_name(model_handle, id)
        sp_hash =  {
          :cols => [:display_name],
          :filter => Filter
        }
        rows = get_objs(model_handle,sp_hash)
        rows && rows.first[:display_name]
      end

      NodeType = 'assembly_node_group'
      Filter = 
        [:and,
         [:eq, :id, id],
         [:eq, :type, NodeType],
         [:eq, :datacenter_datacenter_id, nil]
        ]
    end
  end
end

