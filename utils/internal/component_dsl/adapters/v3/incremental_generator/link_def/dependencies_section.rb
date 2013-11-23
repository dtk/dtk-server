module DTK; class ComponentDSL; class V3
  class IncrementalGenerator; class LinkDef
    class DependenciesSection < self
      def generate()
        ref = @aug_link_def.required(:link_type)
        link_def_links = @aug_link_def.required(:link_def_links)
        if link_def_links.empty?
          raise Error.new("Unexpected that link_def_links is empty")
        end
        opts_choice = Hash.new
        if single_choice = (link_def_links.size == 1) 
          opts_choice.merge!(:omit_component_ref => ref)
        end
        possible_links = @aug_link_def[:link_def_links].map do |link_def_link|
          choice_info(ObjectWrapper.new(link_def_link),opts_choice)
        end
        content = (single_choice ? possible_links.first : {'choices' => possible_links})
        {ref => content}
      end

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

     private
      def choice_info(link_def_link,opts={})
        ret = PrettyPrintHash.new
        remote_cmp_type = link_def_link.required(:remote_component_type)
        cmp_ref = Component.display_name_print_form(remote_cmp_type)
        unless opts[:omit_component_ref] == cmp_ref
          ret['component'] = cmp_ref
        end
        location = 
          case link_def_link.required(:type)
            when 'internal' then 'local'
            when 'external' then 'remote'
            else raise new Error.new("unexpected value for type (#{link_def_link.required(:type)})")
          end
        ret['location'] = location
        if (not link_def_link[:required].nil?) and not link_def_link[:required]
          ret['required'] = false 
        end
        ret
      end

    end
  end; end
end; end; end
