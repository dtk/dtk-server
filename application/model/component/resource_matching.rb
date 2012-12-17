module DTK
  class Component
    class ResourceMatching
      #the input  is a a list of compoennt regs each augmented on target node where it is doing to be staged
      #returns [matches, conflicts] in terms of component templaet ids
      def self.find_matches_and_conflicts(aug_cmp_refs)
        matches = Matches.new
        conflicts = Array.new
        ret = [matches,conflicts]
        return ret if aug_cmp_refs.empty?
        #this is information about any possible relevant componet on a target node 
        cmp_with_attrs = get_matching_components_with_attributes(aug_cmp_refs)
        
        #to determine if there is a match we need to first get attributes for any cmp_ref that may be involved in a match
        #these are ones where there is atleast one matching node/component_type pair
        pruned_cmp_refs = aug_cmp_refs.select do |cmp_ref|
          component_type = cmp_ref[:component_template][:component_type]
          target_node_id = cmp_ref[:target_node_id]
          cmp_with_attrs.find{|cmp|cmp[:component_type] == component_type and cmp[:node_node_id] == target_node_id}
        end 
        return ret if pruned_cmp_refs.empty?

        #get attribute information for pruned_cmp_refs
        cmp_template_attrs = ComponentRef.get_ndx_attribute_values(pruned_cmp_refs)
        
        #this query finds the components and its attributes on the nodes 
        [matches,conflicts]
      end
    
      private
      #each aug_cmp_ref is augmented with target_node_id indicating where it is to be deployed
      def self.get_matching_components_with_attributes(aug_cmp_refs)
        ndx_ret = Hash.new
        target_node_ids = aug_cmp_refs.map{|cmp_ref|cmp_ref[:target_node_id]}.uniq
        cmp_types = aug_cmp_refs.map{|cmp_ref|cmp_ref[:component_template][:component_type]}.uniq
        scalar_cols = [:id,:group_id,:display_name,:node_node_id,:component_type]
        sp_hash = {
          :cols => scalar_cols + [:attribute_values],
          :filter => [:and,[:oneof,:node_node_id,target_node_ids],[:oneof,:component_type,cmp_types]]
        }
        cmp_mh = aug_cmp_refs.first.model_handle(:component)
        Model.get_objs(cmp_mh,sp_hash).each do |cmp|
          cmp_id = cmp[:id]
          pntr = ndx_ret[cmp_id] ||= cmp.hash_subset(*scalar_cols).merge(:attributes => Array.new)
          pntr[:attributes] << cmp[:attribute]
        end
        ndx_ret.values
      end
      
     public
      class Matches < Array
        def ids()
          map{|el|el[:id]}
        end
      end
    end
  end
end
=begin
        {2147512276=>
          [{:component_template_id=>2147507564,
    :display_name=>"test_nginx__real_server_stub",
    :node_node_id=>2147507829,
    :component_template=>
             {:display_name=>"test_nginx__real_server_stub",
      :only_one_per_node=>true,
      :component_type=>"test_nginx__real_server_stub",
      :id=>2147507564,
               :group_id=>2147483650},
    :node=>
             {:display_name=>"real_server",
      :assembly_id=>2147507818,
      :id=>2147507829,
               :group_id=>2147483650},
             :id=>2147507830}],
=end
        

