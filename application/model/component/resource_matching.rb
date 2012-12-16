module DTK
  class Component
    class ResourceMatching
      #the input  is a hash where each key is a node id and its value is a array of teh component templaets to map to it
      #returns [matches, conflicts] in terms of component templaet ids
      def self.find_matches_and_conflicts(cmp_mh,node_id_cmp_template_mapping)
        matches = Array.new
        conflicts = Array.new
        target_node_ids = node_id_cmp_template_mapping.keys
        ndx_component_types = Hash.new
        node_id_cmp_template_mapping.each_value do |cmp_array|
          cmp_array.each{|cmp|ndx_component_types[cmp[:component_type]] ||= true}
        end

        sp_hash = {
          :cols => [:id,:group_id,:display_name,:attribute_values],
          :filter => [:and,[:oneof,:node_node_id,target_node_ids],[:oneof,:component_type,ndx_component_types.keys]]
        }
        #just 'possible' because matching on :node_node_id nad component_types but not combiniation
        possible_matches = Model.get_objs(cmp_mh,sp_hash)
        #this query finds the components and its attributes on the nodes 
        [matches,conflicts]
      end
    end
  end
end
