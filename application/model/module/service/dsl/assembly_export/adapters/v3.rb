module DTK
  class ServiceModule; class AssemblyExport
    r8_require('v2')
    class V3 < V2
     private
      def add_component_link_to_cmp(component_in_ret,out_parsed_port)
        ret = Hash.new
        if component_in_ret.kind_of?(Hash)
          ret = component_in_ret
          component_links = ret.values.first[:component_links] ||= Hash.new
        else # it will be a string
          component_links = Hash.new  
          ret = {component_in_ret => {:component_links => component_links}}
        end
        output_target = "#{out_parsed_port[:node_name]}#{Seperators[:node_component]}#{out_parsed_port[:component_name]}"
        link_def_ref = out_parsed_port[:link_def_ref]
        if existing_links = component_links[link_def_ref]
          if existing_links.kind_of?(Array)
            existing_links << output_target
          else #existing_links.kind_of?(String)
            # turn into array with existing plus new element
            component_links[link_def_ref] = [component_links[link_def_ref],output_target]
          end
        else
          component_links.merge!(link_def_ref => output_target)
        end
        ret 
      end
    end
  end; end
end
