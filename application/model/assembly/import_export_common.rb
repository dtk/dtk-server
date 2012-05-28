module XYZ
  module AssemblyImportExportCommon
    Seperators = {
      :module_component => "::",
      :component_port => "/",
      :assembly_node => "/",
      :node_component => "/",
      :component_link_def_ref => "/"
    }
    class AssemblyImportPortRef < SimpleHashObject
      def self.parse(port_ref)
        if port_ref =~ PortRefRegex
          node = $1; cmp_type_x = $2; link_def_ref = $3
          #TODO: global for "__"
          cmp_type = cmp_type_x.gsub(ModCompRegex,"__")
          new(:node => node,:component_type => cmp_type, :link_def_ref => link_def_ref)
        else
          raise Error.new("ill-formed port ref (#{port_ref})")
        end     
      end
      PortRefRegex = Regexp.new("(^.+)#{Seperators[:node_component]}(.+)#{Seperators[:component_link_def_ref]}(.+$)")
      ModCompRegex = Regexp.new(Seperators[:module_component])
      
      def matching_id(ports)
        nil
      end
    end
  end
end
