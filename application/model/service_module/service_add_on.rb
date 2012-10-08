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
        pp [:debug,module_name,meta_file,hash_content]
        assembly_id = ret_assembly_id(:assembly)
        sub_assembly_id = ret_assembly_id(:add_on_sub_assembly)
        pp [assembly_id,sub_assembly_id]
        port_link_info = Assembly.ret_add_on_port_links(ports,hash_content["port_links"])
        pp port_link_info
      end
     private
      attr_reader :library_idh, :module_name, :meta_file, :hash_content, :ports

      def ret_assembly_id(field)
        unless assembly_name = hash_content[field.to_s]
          raise ErrorUsage("Field (#{field}) not given in the service add-on file #{meta_file}")
        end
        ref = ServiceModule.assembly_ref(module_name,assembly_name)
        unless ret = library_idh.get_child_id_handle(:component,ref).get_id()
          raise ErrorUsage("Field (#{field}) has value (#{assembly_name}) which is not avlaid assembly refernce")
        end
        ret
      end
    end
  end
end
=begin
 "test2",
 "assemblies/hdfs/add-ons/slave.json",
 {"add_on_sub_assembly"=>"hdfs-slave",
  "description"=>"Adds slave node",
  "assembly"=>"hdfs",
  "port_links"=>
   [{"hdfs/master/hdp-hadoop::namenode/namenode_conn"=>
      "hdfs-slave/slave/hdp-hadoop::namenode-conn/namenode_conn"}]}]
[{:port_link=>{"output_id"=>2147519602, "input_id"=>2147519601},
  :assembly_refs=>{:output=>"hdfs", :input=>"hdfs-slave"}}]
=end
