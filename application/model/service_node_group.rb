module DTK
  class ServiceNodeGroup < Node
    def get_node_members()
      #if ndx_node_members is not empty then {id_handle-> [ng_el1,ng_el2,..]} will be returned
      self.class.get_ndx_node_members([id_handle()]).values.first||[]
    end

    def self.get_ndx_node_members(node_group_idhs)
      ret = Hash.new
      return ret if node_group_idhs.empty?
      sp_hash = {
        :cols => [:id,:display_name,:node_members],
        :filter => [:oneof,:id,node_group_idhs.map{|ng|ng.get_id()}]
      }
      mh = node_group_idhs.first.createMH()
      get_objs(mh,sp_hash).each do |ng|
        ndx = ng[:id]
        (ret[ndx] ||= Array.new) << ng[:node_member]
      end
      ret
    end
    def self.get_attributes_to_copy_to_target_refs(node_group_idhs)
      Node.get_target_ref_attributes(node_group_idhs,:cols=>CopyToTargetRefAttrs)
    end
    CopyToTargetRefAttrs = (Attribute.common_columns + [:ref,:node_node_id]).uniq - [:id]

    def self.check_valid_id(model_handle,id)
      IdNameHelper.check_valid_id(model_handle,id)
    end
    def self.name_to_id(model_handle,name)
      IdNameHelper.name_to_id(model_handle,name)
    end
    def self.id_to_name(model_handle, id)
      IdNameHelper.id_to_name(model_handle, id)
    end

    def destroy_and_delete(opts={})
      get_node_members().map{|node|node.destroy_and_delete(opts)}
    end
    def delete_object(opts={})
      get_node_members().map{|node|node.delete_object(opts)}
    end


   private
    module IdNameHelper
      def self.check_valid_id(model_handle,id)
        check_valid_id_helper(model_handle,id,filter(:id => id))
      end
      def self.name_to_id(model_handle,name)
        sp_hash =  {
        :cols => [:id],
        :filter => filter(:display_name => name)
        }
        name_to_id_helper(model_handle,name,sp_hash)
      end
      def self.id_to_name(model_handle, id)
        sp_hash =  {
          :cols => [:display_name],
          :filter => filter(:id => id)
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

