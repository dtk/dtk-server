module DTK; class ComponentDSL; class V3
  class IncrementalGenerator; class LinkDef
    class DependenciesSection < self
      def merge_fragment!(full_hash,fragment,context={})
        ret = full_hash
        return ret unless fragment
        component_fragment = component_fragment(full_hash,context[:component_template])
        if dependencies_fragment = component_fragment['dependencies']
          fragment.each do |key,content|
            update_depends_on_fragment!(dependencies_fragment,key,content)
          end
        else
          component_fragment['dependencies'] = [fragment]
        end
        ret
      end
    end
  end; end
end; end; end
