module DTK
  class ServiceAddOn
    private

    class Import 
      include ServiceDSLCommonMixin
      def initialize(container_idh,module_name,dsl_file,hash_content,ports,aug_assembly_nodes)
        @container_idh = container_idh
        @module_name = module_name
        @dsl_file = dsl_file
        @hash_content = hash_content
        @ports = ports
        augmnent_with_parsed_nanems_and_assembly_ids!(@ports,aug_assembly_nodes)
        @aug_assembly_nodes = aug_assembly_nodes
        @assemblies = find_assemblies(aug_assembly_nodes)
      end

      def import
        type = (dsl_file =~ DslRegExp;$1)
        assembly,assembly_ref = ret_assembly_info(:assembly)
        sub_assembly,sa_ref = ret_assembly_info(:add_on_sub_assembly)
        ao_input_hash = {
          display_name: type,
          description: hash_content["description"],
          type: type,
          sub_assembly_id: sub_assembly[:id]
        }
        port_links = import_add_on_port_links(ports,hash_content["port_links"],assembly,sub_assembly)
        unless port_links.empty?
          ao_input_hash.merge!(port_link: port_links)
        end
        
        node_bindings = ServiceNodeBinding.import_add_on_node_bindings(@aug_assembly_nodes,hash_content["node_bindings"])
        unless node_bindings.empty?
          ao_input_hash.merge!(service_node_binding: node_bindings)
        end

        input_hash = {assembly_ref => {service_add_on: {type => ao_input_hash}}}
        Model.import_objects_from_hash(container_idh,"component" =>  input_hash)
      end

      def self.dsl_filename_path_info
        {
          regexp: DslRegExp,
          path_depth: 4
        }
      end

      private

      def import_add_on_port_links(ports,add_on_port_links,assembly,sub_assembly)
        ret = {}
        return ret if (add_on_port_links||[]).empty?
        assembly_list = [assembly,sub_assembly]
        add_on_port_links.each do |ao_pl_ref,ao_pl|
          link = ao_pl["link"]
          input_assembly,input_port = add_on_parse(link.values.first,assembly_list)
          output_assembly,output_port = add_on_parse(link.keys.first,assembly_list)
          input_id = input_port.matching_id(ports)
          output_id = output_port.matching_id(ports)
          output_is_local = (output_assembly == assembly[:display_name]) 
          pl_hash = {"input_id" => input_id,"output_id" => output_id, "output_is_local" => output_is_local, "required" => ao_pl["required"]}
          ret.merge!(ao_pl_ref => pl_hash)
        end
        ret
      end

      def add_on_parse(add_on_port_ref,assembly_list)
        ServiceModule::AssemblyImport::PortRef::AddOn.parse(add_on_port_ref,assembly_list)
      end
      
      def augment_with_assembly_ids!(_ports)
        nil
      end

      DslRegExp = Regexp.new("add-ons/([^/]+)\.json$")    
      attr_reader :container_idh, :module_name, :dsl_file, :hash_content, :ports

      def import_port_link(_port_link_info)
      end

      def find_assemblies(aug_assembly_nodes)
        ndx_ret = {}
        aug_assembly_nodes.each do |n|
          assembly = n[:assembly]
          ndx_ret[assembly[:id]] ||= assembly
        end
        ndx_ret.values
      end

      def augmnent_with_parsed_nanems_and_assembly_ids!(ports,aug_assembly_nodes)
        ServiceModule::AssemblyImport.augment_with_parsed_port_names!(ports)
        ndx_node_assembly = aug_assembly_nodes.inject({}){|h,n|h.merge(n[:id] => n[:assembly][:id])}
        ports.each do |p|
          p[:assembly_id] ||= ndx_node_assembly[p[:node_node_id]]
        end
      end

      # returns [assembly,assembly_ref]
      def ret_assembly_info(field)
        unless name = hash_content[field.to_s]
          raise ErrorUsage("Field (#{field}) not given in the service add-on file #{dsl_file}")
        end
        unless assembly = @assemblies.find{|a|a[:display_name] == name}
          Log.error("Field (#{field}) has value (#{name}) which is not a valid assembly reference")
        end
        raise Error.new("if use need to pass in service_module and call service_module.assembly_ref(name)")
        #        [assembly,ServiceModule.assembly_ref(module_name,name)]
      end
    end
  end
end
