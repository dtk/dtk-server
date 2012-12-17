module DTK
  class Component
    class ResourceMatching
      #the input  is a hash where each key is a node id and its value is a array of teh component refs taht also have :component_template attribute
      #returns [matches, conflicts] in terms of component templaet ids
      def self.find_matches_and_conflicts(cmp_ref_mh,node_id_cmp_ref_mapping)
        matches = Matches.new
        conflicts = Array.new
        target_node_ids = node_id_cmp_ref_mapping.keys
        ndx_component_types = Hash.new
        node_id_cmp_ref_mapping.each_value do |cmp_refs|
          cmp_refs.each{|cmp_ref|ndx_component_types[cmp_ref[:component_template][:component_type]] ||= true}
        end

        sp_hash = {
          :cols => [:id,:group_id,:display_name,:attribute_values],
          :filter => [:and,[:oneof,:node_node_id,target_node_ids],[:oneof,:component_type,ndx_component_types.keys]]
        }
        #just 'possible' because matching on :node_node_id nad component_types but not combiniation
        cmp_mh = cmp_ref_mh.createMH(:component)
        possible_matches = Model.get_objs(cmp_mh,sp_hash)
        #TODO: remove the ones taht are not matches

        #get attribute information for relevant compoennt_refs
        #TODO: stub
        cmp_refs = node_id_cmp_ref_mapping.values.flatten
        cmp_template_attrs = ComponentRef.get_ndx_attribute_values(cmp_refs)

        #this query finds the components and its attributes on the nodes 
        [matches,conflicts]
      end
    end
   private
    
    #each match pair is of the form {:cmp_instance => cmp_instance, :cmp_ref => cmp}
    def self.find_matches_and_conflicts_aux(match_pairs) 
      
    end
    public
    class Matches < Array
      def ids()
        map{|el|el[:id]}
      end
    end
  end
end
