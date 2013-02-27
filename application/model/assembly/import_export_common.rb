module DTK
  module AssemblyImportExportCommon
    Seperators = {
      :module_component => "::",
      :component_version => ":",
      :component_port => "/",
      :assembly_node => "/",
      :node_component => "/",
      :component_link_def_ref => "/"
    }

    class AssemblyImportPortRef < SimpleHashObject
      def self.parse(port_ref,assembly_id=nil)
        if port_ref =~ PortRefRegex
          node = $1; cmp_name = $2; link_def_ref = $3
          hash = {:node => node,:component_type => component_type(cmp_name),:link_def_ref => link_def_ref}
          if assembly_id
            hash.merge!(:assembly_id => assembly_id)
          end
          new(hash)
        else
          raise Error.new("ill-formed port ref (#{port_ref})")
        end     
      end
      def self.parse_service_link(input_node,input_cmp_name,service_link_hash)
        unless service_link_hash.size == 1
          raise Error.new("ill-formed service link (#{service_link_hash.inject})")
        end
        link_def_ref = service_link_hash.keys.first
        if service_link_hash.values.first =~ ServiceLinkTarget
          output_node = $1; output_cmp_name = $2
          input = {:node => input_node,:component_type => component_type(input_cmp_name), :link_def_ref => link_def_ref}
          output = {:node => output_node,:component_type => component_type(output_cmp_name), :link_def_ref => link_def_ref}
          {:input => new(input), :output => new(output)}
        else
          raise Error.new("ill-formed service link (#{service_link_hash.inject}")
        end     
      end
      class << self
        def component_type(cmp_name)
          #TODO: global for "__"
          cmp_type = cmp_name.gsub(ModCompRegex,"__")
        end
      end
      PortRefRegex = Regexp.new("(^.+)#{Seperators[:node_component]}(.+)#{Seperators[:component_link_def_ref]}(.+$)")
      ModCompRegex = Regexp.new(Seperators[:module_component])
      ServiceLinkTarget= Regexp.new("(^.+)#{Seperators[:node_component]}(.+$)")

      #ports are augmented with field :parsed_port_name
      def matching_id(aug_ports)
        match = aug_ports.find do |port|
          p = port[:parsed_port_name]
          node = port[:node][:display_name]
          if self[:component_type] == p[:component_type] and self[:link_def_ref] == p[:link_def_ref] and node == self[:node] 
            self[:assembly_id].nil? or (self[:assembly_id] == port[:assembly_id])
          end
        end
        if match
          match[:id]
        else
          raise Error.new("Cannot find match to (#{self.inspect})")
        end
      end
      class AddOn < self
        #returns assembly ref, port_ref
        def self.parse(add_on_port_ref,assembly_list)
          assembly_name,port_ref = (add_on_port_ref =~ AOPortRefRegex; [$1,$2])
          unless assembly_match = assembly_list.find{|a|a[:display_name] == assembly_name}
            assembly_names = assembly_list.map{|a|a[:display_name]}
            Log.error("Assembly name in add-on port link (#{assembly_name}) is illegal; must be one of (#{assembly_names.join(',')})")
#            raise ErrorUsage.new("Assembly name in add-on port link (#{assembly_name}) is illegal; must be one of (#{assembly_names.join(',')})")
          end
          [assembly_name,super(port_ref,assembly_match[:id])]
        end
        AOSep = Seperators[:assembly_node]
        AOPortRefRegex = Regexp.new("(^[^#{AOSep}]+)#{AOSep}(.+$)")
      end
    end
  end
end
