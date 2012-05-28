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
          new(:node => node,:compoment_type => cmp_type, :link_def_ref => link_def_ref)
        else
          raise Error.new("ill-formed port ref (#{port_ref})")
        end     
      end
      PortRefRegex = Regexp.new("(^.+)#{Seperators[:node_component]}(.+)#{Seperators[:component_link_def_ref]}(.+$)")
      ModCompRegex = Regexp.new(Seperators[:module_component])

      def self.port_link_ref(in_aipr,out_aipr)
        "#{in_aipr[:node]}-#{out_aipr[:node]}-#{in_aipr[:link_def_ref]}"
      end

      def ret_uri_form(assembly_ref)
        p = Port.ref_from_component_and_link_def_ref("component_external",self[:component_type],self[:link_def_ref])
        #TODO: global for "--"
        "/node/#{assembly_ref}--#{self[:node]}/port/#{p}"
      end
    end
  end
end
