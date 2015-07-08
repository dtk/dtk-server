module DTK
  class Component
    class ResourceMatching
      # the input  is a a list of compoennt regs each augmented on target node where it is doing to be staged
      # returns [matches, conflicts] in terms of component templaet ids
      def self.find_matches_and_conflicts(aug_cmp_refs)
        matches = Matches.new
        conflicts = []
        ret = [matches,conflicts]
        return ret if aug_cmp_refs.empty?
        # this is information about any possible relevant componet on a target node
        cmp_with_attrs = get_matching_components_with_attributes(aug_cmp_refs)

        # to determine if there is a match we need to first get attributes for any cmp_ref that may be involved in a match
        # these are ones where there is atleast one matching node/component_type pair
        pruned_cmp_refs = aug_cmp_refs.select do |cmp_ref|
          component_type = cmp_ref[:component_template][:component_type]
          target_node_id = cmp_ref[:target_node_id]
          cmp_with_attrs.find{|cmp|cmp[:component_type] == component_type && cmp[:node_node_id] == target_node_id}
        end
        return ret if pruned_cmp_refs.empty?

        # get attribute information for pruned_cmp_refs
        ndx_cmp_ref_attrs = get_ndx_component_ref_attributes(pruned_cmp_refs)

        # now del withj matching taht takes into account resource defs keys

        # this query finds the components and its attributes on the nodes
        [matches,conflicts]
      end

      private

      # each aug_cmp_ref is augmented with target_node_id indicating where it is to be deployed
      def self.get_matching_components_with_attributes(aug_cmp_refs)
        ndx_ret = {}
        target_node_ids = aug_cmp_refs.map{|cmp_ref|cmp_ref[:target_node_id]}.uniq
        cmp_types = aug_cmp_refs.map{|cmp_ref|cmp_ref[:component_template][:component_type]}.uniq
        scalar_cols = [:id,:group_id,:display_name,:node_node_id,:component_type]
        sp_hash = {
          cols: scalar_cols + [:attribute_values],
          filter: [:and,[:oneof,:node_node_id,target_node_ids],[:oneof,:component_type,cmp_types]]
        }
        cmp_mh = aug_cmp_refs.first.model_handle(:component)
        Model.get_objs(cmp_mh,sp_hash).each do |cmp|
          cmp_id = cmp[:id]
          pntr = ndx_ret[cmp_id] ||= cmp.hash_subset(*scalar_cols).merge(attributes: [])
          pntr[:attributes] << cmp[:attribute]
        end
        ndx_ret.values
      end

      # looks at both the component template attribute value plus the overrides
      # indexed by compoennt ref id
      # we assume each component ref has component_template_id set
      def self.get_ndx_component_ref_attributes(cmp_refs)
        ret = {}
        return ret if cmp_refs.empty?

        # get template attribute values
        sp_hash = {
          cols: [:id,:group_id,:display_name,:attribute_value,:component_component_id],
          filter: [:oneof,:component_component_id,cmp_refs.map{|r|r[:component_template_id]}]
        }
        attr_mh = cmp_refs.first.model_handle(:attribute)
        ndx_template_to_ref = cmp_refs.inject({}){|h,cmp_ref|h.merge(cmp_ref[:component_template_id] => cmp_ref[:id])}

        ndx_attrs = Model.get_objs(attr_mh,sp_hash).inject({}) do |h,attr|
          cmp_ref_id = ndx_template_to_ref[attr[:component_component_id]]
          h.merge(attr[:id] => attr.merge(component_ref_id: cmp_ref_id))
        end

        # get override attributes
        sp_hash = {
          cols: [:id,:group_id,:display_name,:attribute_value,:attribute_template_id],
          filter: [:oneof,:component_ref_id,cmp_refs.map{|r|r[:id]}]
        }
        override_attr_mh = attr_mh.createMH(:attribute_override)
        Model.get_objs(override_attr_mh,sp_hash) do |ovr_attr|
          attr = ndx_attrs[ovr_attr[:attribute_template_id]]
          if ovr_attr[:attribute_value]
            attr[:attribute_value] = ovr_attr[:attribute_value]
          end
        end

        ret = cmp_refs.inject({}){|h,cmp_ref|h.merge(cmp_ref[:id] => [])}
        ndx_attrs.each_value{|attr|ret[attr[:component_ref_id]] << attr}
        ret
      end

      public

      class Matches < Array
        def ids
          map{|el|el[:id]}
        end
      end
    end
  end
end
#         {2147512276=>
#           [{:component_template_id=>2147507564,
#     :display_name=>"test_nginx__real_server_stub",
#     :node_node_id=>2147507829,
#     :component_template=>
#              {:display_name=>"test_nginx__real_server_stub",
#       :only_one_per_node=>true,
#       :component_type=>"test_nginx__real_server_stub",
#       :id=>2147507564,
#                :group_id=>2147483650},
#     :node=>
#              {:display_name=>"real_server",
#       :assembly_id=>2147507818,
#       :id=>2147507829,
#                :group_id=>2147483650},
#              :id=>2147507830}],


