module DTK; class ServiceNodeGroup
  module CloneToNodeMembers
    module Mixin
      # returns hash with key being component id and values being id handles on nodes taht dont have that component
      # if opts[:node_group_components] then filter to only include components corresponding 
      # to these node_group_components
      def get_ndx_components_not_cloned(node_members,opts={})
        ret = Hash.new
        return ret if node_members.empty?()

        sp_hash = {
          :cols => [:id,:group_id,:display_name,:node_node_id],
          :filter => [:oneof, :node_node_id, node_members.map{|n|n.id}+[id()]]
        }
        # ndx_cmps is double indexed by [node_id][cmp_id]
        ndx_cmps = Hash.new
        Model.get_objs(model_handle(:component),sp_hash).each do |r|
          node_id = r[:node_node_id]
          cmp_id = r[:id]
          (ndx_cmps[node_id] ||= Hash.new).merge!(cmp_id => r)
        end
        ng_cmp_ids = (ndx_cmps[id()]||{}).keys
        if ng_cmps = opts[:node_group_components]
          ng_cmp_ids = ng_cmp_ids & ng_cmps.map{|r|r.id} 
        end
        return if ng_cmp_ids.empty?
        node_members.each do |node|
          needed_cmp_ids = ng_cmp_ids - (ndx_cmps[node.id]||{}).keys
          needed_cmp_ids.each{|cmp_id|(ret[cmp_id] ||= Array.new) << node.id_handle()}
        end
        ret
      end
    end
    module ClassMixin
    end
  end
end; end

