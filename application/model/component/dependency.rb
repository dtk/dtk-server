module DTK
  class Component
    #TODO: move to be related to component order
    module DependencyClassMixin
      def get_internode_dependencies(state_change_list)
        ret = Array.new
        aug_attr_list = Attribute.aug_attr_list_from_state_change_list(state_change_list)
        Attribute.dependency_analysis(aug_attr_list) do |attr_in,link,attr_out|
          if attr_guard = GuardedAttribute.create(attr_in,link,attr_out)
            guard = attr_guard[:guard]
            guarded = attr_guard[:guarded]
            cmp_dep = {
              :guard => {:component => guard[:component], :node => guard[:node]},
              :guarded => {:component => guarded[:component], :node => guarded[:node]}
            }
            #guarded has to go after guard
            #flat list of dependencies as oppossed to collecting all deps for one component
            #attr_guard has relationship between attributes; stripping out attr info; consequently same compoennt relationship can be in more than once
            ret << cmp_dep
          end
        end

        # Amar: changing format for algorithm
        internode_dependencies = Array.new
        ret.each do |dep|
          internode_dependencies << {
            :node_dependency => { dep[:guarded][:node][:id] => dep[:guard][:node][:id] },
            :node_dependency_names => { dep[:guarded][:node][:display_name] => dep[:guard][:node][:display_name] },
            :component_dependency => { dep[:guarded][:component][:id] => [dep[:guard][:component][:id]] },
            :component_dependency_names => { dep[:guarded][:component][:display_name] => [dep[:guard][:component][:display_name]] }
          }
        end
        return internode_dependencies
      end

    end
  end
end
