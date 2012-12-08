module DTK
  class ServiceAddOn
   private
    class Import 
      def initialize(library_idh,module_name,meta_file,hash_content,ports,aug_assembly_nodes)
        @library_idh = library_idh
        @module_name = module_name
        @meta_file = meta_file
        @hash_content = hash_content
        @ports = ports
        @aug_assembly_nodes = aug_assembly_nodes
      end
      def import()
        type = (meta_file =~ MetaRegExp;$1)
        assembly_name,assembly_ref = ret_assembly_info(:assembly)
        sub_assembly_name,sa_ref,sub_assembly_id = ret_assembly_info(:add_on_sub_assembly)
        ao_input_hash = {
          :display_name => type,
          :description => hash_content["description"],
          :type => type,
          :sub_assembly_id => sub_assembly_id
        }
        port_links = import_add_on_port_links(ports,hash_content["port_links"],assembly_name,sub_assembly_name)
        unless port_links.empty?
          ao_input_hash.merge!(:port_link => port_links)
        end
        
        node_bindings = ServiceNodeBinding.import_add_on_node_bindings(@aug_assembly_nodes,hash_content["node_bindings"])
        unless node_bindings.empty?
          ao_input_hash.merge!(:service_node_binding => node_bindings)
        end

        input_hash = {assembly_ref => {:service_add_on => {type => ao_input_hash}}}
        Model.import_objects_from_hash(library_idh,"component" =>  input_hash)
      end

      def self.meta_filename_path_info()
        {
          :regexp => MetaRegExp,
          :path_depth => 4
        }
      end

     private
      include AssemblyImportExportCommon
      def import_add_on_port_links(ports,add_on_port_links,assembly_name,sub_assembly_name)
        ret = Hash.new
        return ret if (add_on_port_links||[]).empty?
        #augment ports with parsed display_name
        ServiceModule::AssemblyImport.augment_with_parsed_port_names!(ports)
        assembly_names = [assembly_name,sub_assembly_name]
        add_on_port_links.each do |ao_pl_ref,ao_pl|
          link = ao_pl["link"]
          input_assembly,input_port = AssemblyImportPortRef::AddOn.parse(link.values.first,assembly_names)
          output_assembly,output_port = AssemblyImportPortRef::AddOn.parse(link.keys.first,assembly_names)
          input_id = input_port.matching_id(ports)
          output_id = output_port.matching_id(ports)
          output_is_local = (output_assembly == assembly_name) 
          pl_hash = {"input_id" => input_id,"output_id" => output_id, "output_is_local" => output_is_local, "required" => ao_pl["required"]}
          ret.merge!(ao_pl_ref => pl_hash)
        end
        ret
      end

      MetaRegExp = Regexp.new("add-ons/([^/]+)\.json$")    
      attr_reader :library_idh, :module_name, :meta_file, :hash_content, :ports

      def import_port_link(port_link_info)
      end
      #returns [assembly_name,assembly_ref,assembly_id]
      def ret_assembly_info(field)
        unless name = hash_content[field.to_s]
          raise ErrorUsage("Field (#{field}) not given in the service add-on file #{meta_file}")
        end
        ref = ServiceModule.assembly_ref(module_name,name)
        unless id = library_idh.get_child_id_handle(:component,ref).get_id()
          Log.error("Field (#{field}) has value (#{name}) which is not a valid assembly reference")
#          raise ErrorUsage.new("Field (#{field}) has value (#{name}) which is not a valid assembly reference")
        end
        [name,ref,id]
      end
    end
  end
end
