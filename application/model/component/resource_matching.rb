module DTK
  class Component
    class ResourceMatching
      #the input  is a hash where each key is a node id and its value is a array of teh component refs taht also have :component_template attribute
      #returns [matches, conflicts] in terms of component templaet ids
      def self.find_matches_and_conflicts(cmp_ref_mh,node_id_cmp_ref_mapping)
        matches = Matches.new
        conflicts = Array.new
        target_node_ids = node_id_cmp_ref_mapping.keys
        cmp_refs = node_id_cmp_ref_mapping.values.flatten
        
##group as one fn
        cmp_types = cmp_refs.map{|cmp_ref|cmp_ref[:component_template][:component_type]}.uniq
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:attribute_values],
          :filter => [:and,[:oneof,:node_node_id,target_node_ids],[:oneof,:component_type,cmp_types]]
        }
        cmp_mh = cmp_ref_mh.createMH(:component)
        ndx_cmp_attr_info = Hash.new
        Model.get_objs(cmp_mh,sp_hash).each do |cmp|
          cmp_id = cmp[:id]
          pntr = ndx_cmp_attr_info[cmp_id] ||= cmp.hash_subset(:id,:group_id,:display_name).merge(:attributes => Array.new)
          pntr[:attributes] << cmp[:attribute]
        end
#end group as one fn
        
        #to determine if there is a match we need to first get attributes for any cmp_ref that may be involved in a match
        #these are ones where there is atleast one matching node/component_type pair
        pruned_cmp_refs = cmp_refs.reject do |cmp_ref|             
          #STUB
        end

        #get attribute information for relevant compoennt_refs
        #TODO: stub
        cmp_template_attrs = ComponentRef.get_ndx_attribute_values(pruned_cmp_refs)

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
