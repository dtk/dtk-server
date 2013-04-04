module DTK
  class Component
    module DependencyClassMixin

      #this provides for each component, what other components it depends on
      def get_component_type_and_dependencies(id_handles)
        sample_idh = id_handles.first
        #TODO: switched to use inherited dependencies; later will allow dependencies directly on component instances and have
        #them override
        #TODO: should also modifying cloning so  component instances not getting the dependencies
        sp_hash = {
#          :cols => [:id,:dependencies, :extended_base, :component_type],
          :cols => [:id,:inherited_dependencies, :extended_base, :component_type],
          :filter => [:oneof, :id, id_handles.map{|idh|idh.get_id()}]
        }
        components = get_objs(sample_idh.createMH,sp_hash)
        find_component_dependencies(components)
      end

      def ordered_components(components,&block)
        ndx_cmps = components.inject({}){|h,cmp|h.merge(cmp[:id] => cmp)}
        cmp_deps = find_component_dependencies(components)
        Task::Action::OnComponent.generate_component_order(cmp_deps).each do |(component_id,deps)|
          block.call(ndx_cmps[component_id])
        end
      end

      #FOR_AMAR
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
        ret
      end

     private
      #assumption that this is called with components having keys :id,:dependencies, :extended_base, :component_type 
      def find_component_dependencies(components)
        ret = Hash.new
        cmp_idhs = Array.new
        components.each do |cmp|
          unless pntr = ret[cmp[:id]]
            pntr = ret[cmp[:id]] = {:component_type => cmp[:component_type], :component_dependencies => Array.new}
            cmp_idhs << cmp.id_handle()
          end
          if cmp[:extended_base]
            pntr[:component_dependencies] << cmp[:extended_base]
          elsif deps = cmp[:dependencies]
            #process dependencies
            #TODO: hack until we have macros which will stamp the dependency to make this easier to detect
            #looking for signature where dependency has
            #:search_pattern=>{:filter=>[:and, [:eq, :component_type, <component_type>]
            filter = (deps[:search_pattern]||{})[":filter".to_sym]
            if filter and deps[:type] == "component"
              if filter[0] == ":eq" and filter[1] == ":component_type"
                pntr[:component_dependencies] << filter[2]
              end
            end
          end
        end
        ComponentOrder.update_with_applicable_dependencies!(ret,cmp_idhs)
      end
    end
  end
end
