module DTK; class ComponentDSL; class V3
  class IncrementalGenerator; class LinkDef
    class LinkDefsSection < self
      def generate()
        link_def_links = @aug_link_def.required(:link_def_links)
        if link_def_links.empty?
          raise Error.new("Unexpected that link_def_links is empty")
        end
        @aug_link_def[:link_def_links].inject(PossibleLinks.new) do |pl,link_def_link|
          cmp,link = choice_info(ObjectWrapper.new(link_def_link))
          pl.deep_merge(cmp,link)
        end
      end
      
      def merge_fragment!(full_hash,fragment,context={})
        ret = full_hash
        return ret unless fragment
        component_fragment = component_fragment(full_hash,context[:component_template])
        if link_defs_fragment = component_fragment['link_defs']
          component_fragment['link_defs'] = PossibleLinks.reify(link_defs_fragment)
          fragment.each do |cmp,link|
            component_fragment['link_defs'] = component_fragment['link_defs'].deep_merge(cmp,link)
          end
        else
          component_fragment['link_defs'] = fragment
        end
        ret
      end

     private
      #returns cmp,link
      def choice_info(link_def_link)
        link = Link.new
        remote_cmp_type = link_def_link.required(:remote_component_type)
        cmp = Component.display_name_print_form(remote_cmp_type)
        location = 
          case link_def_link.required(:type)
          when 'internal' then 'local'
          when 'external' then 'remote'
          else raise new Error.new("unexpected value for type (#{link_def_link.required(:type)})")
          end
        link['location'] = location
        if dependency_name = @aug_link_def[:link_type]
          unless dependency_name == cmp
            link['dependency_name'] = dependency_name
          end
        end
        if (not link_def_link[:required].nil?) and not link_def_link[:required]
          link['required'] = false 
        end
        ams = link_def_link.object.attribute_mappings() 
        if ams and not ams.empty?
          link['attribute_mappings'] = ams.map{|am|attribute_mapping(ObjectWrapper.new(am),remote_cmp_type)}
        end
        [cmp,link]
      end
    end
  end; end
end; end; end
