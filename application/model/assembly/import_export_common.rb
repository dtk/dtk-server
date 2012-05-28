module XYZ
  module AssemblyImportExportCommon
    Seperators = {
      :module_component => "::",
      :component_port => "/",
      :assembly_node => "/",
      :node_component => "/",
      :component_link_def_ref => "/"
    }
    PortRefRegex = Regexp.new("(^.+)#{Seperators[:node_component]}(.+)#{Seperators[:component_link_def_ref]}(.+$)")
    ModCompRegex = Regexp.new(Seperators[:module_component])
    #TODO: globals for "--" and "__"
    def parse_port_ref(assembly_ref,port_ref)
      if port_ref =~ PortRefRegex
        node = $1; cmp_type_x = $2; link_def_ref = $3
        cmp_type = cmp_type_x.gsub(ModCompRegex,"__")
        p = Port.ref_from_component_and_link_def_ref("component_external",cmp_type,link_def_ref)
        "/node/#{assembly_ref}--#{node}/port/#{p}"
      else
        raise Error.new("ill-formed port ref (#{port_ref})")
      end
    end
  end
end
