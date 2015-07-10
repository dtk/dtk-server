module DTK
  class ServiceModule; class AssemblyExport
    r8_require('v2')
    class V3 < V2
      private

      def add_component_link_to_cmp(component_in_ret, out_parsed_port)
        ret = {}
        if component_in_ret.is_a?(Hash)
          ret = component_in_ret
          component_links = ret.values.first[:component_links] ||= {}
        else # it will be a string
          component_links = {}
          ret = { component_in_ret => { component_links: component_links } }
        end
        output_target = component_link_output_target(out_parsed_port)
        link_def_ref = out_parsed_port[:link_def_ref]
        if existing_links = component_links[link_def_ref]
          if existing_links.is_a?(Array)
            existing_links << output_target
          else #existing_links.kind_of?(String)
            # turn into array with existing plus new element
            component_links[link_def_ref] = [component_links[link_def_ref], output_target]
          end
        else
          component_links.merge!(link_def_ref => output_target)
        end
        ret
      end

      def component_link_output_target(parsed_port)
        ret = "#{parsed_port[:node_name]}#{Seperators[:node_component]}#{parsed_port[:component_name]}"
        if title = parsed_port[:title]
          ret << "#{Seperators[:title_before]}#{title}#{Seperators[:title_after]}"
        end
        ret
      end

    end
  end; end
end
