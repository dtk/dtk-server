module DTK; class ServiceModule
  class AssemblyImport
    r8_require('v2')
    class V3 < V2
      def self.parse_component_links(assembly_hash)
        ret = Array.new
        (assembly_hash["nodes"]||{}).each_pair do |input_node_name,node_hash|
          components = node_hash["components"]||[]
          components = [components] unless components.kind_of?(Array)
          components.each do |input_cmp|
            if input_cmp.kind_of?(Hash) 
              input_cmp_name = input_cmp.keys.first
              component_links = input_cmp.values.first["component_links"]||{}
              ParsingError.raise_error_if_not(component_links,Hash,:type => "component link",:context => input_cmp)
              component_links.each_pair do |link_def_type,targets|
                Array(targets).each do |target|
                  component_link_hash = {link_def_type => target}
                  ret << PortRef.parse_component_link(input_node_name,input_cmp_name,component_link_hash)
                end
              end
            end
          end
        end
        ret
      end
    end
  end
end; end
