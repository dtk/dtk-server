module DTK
  class ServiceAddOn < Model
    def self.import(library_idh,module_name,meta_file,hash_content,ports)
      Import.new(library_idh,module_name,meta_file,hash_content,ports).import()
    end

    def self.meta_filename_path_info()
      {
        :regexp => MetaRegExp,
        :path_depth => 4
      }
    end
    MetaRegExp = Regexp.new("add-ons/([^/]+)\.json$")    

    class Import 
      def initialize(library_idh,module_name,meta_file,hash_content,ports)
        @library_idh = library_idh
        @module_name = module_name
        @meta_file = meta_file
        @hash_content = hash_content
        @ports = ports
      end
      def import()
        type = (meta_file =~ MetaRegExp;$1)
        assembly_name,assembly_ref = ret_assembly_info(:assembly)
        sub_assembly_name,sa_ref,sub_assembly_id = ret_assembly_info(:add_on_sub_assembly)
        ao_input_hash = {
          :display_name => type,
          :type => type,
          :sub_assembly_id => sub_assembly_id
        }
        port_links = Assembly.import_add_on_port_links(ports,hash_content["port_links"],assembly_name,sub_assembly_name)
        ao_input_hash.merge!(:port_link => port_links)
        input_hash = {assembly_ref => {:service_add_on => {type => ao_input_hash}}}
        Model.import_objects_from_hash(library_idh,{"component" =>  input_hash})
      end
     private
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
          raise ErrorUsage("Field (#{field}) has value (#{name}) which is not a valid assembly refernce")
        end
        [name,ref,id]
      end
    end
  end
end
