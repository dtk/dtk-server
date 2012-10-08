module DTK
  class ServiceAddOn < Model
    def self.import(module_branch,ports,meta_file,hash_content)
      type = (meta_file =~ MetaRegExp;$1)
      pp [:debug,module_branch, meta_file,type]
      port_link_info = Assembly.ret_add_on_port_links(ports,hash_content["port_links"])
      pp port_link_info
    end
    def self.meta_filename_path_info()
      {
        :regexp => MetaRegExp,
        :path_depth => 4
      }
    end
    MetaRegExp = Regexp.new("add-ons/([^/]+)\.json$")
  end
end
=begin
  {:type=>"component_external",
   :node_node_id=>2147519886,
   :ref=>"component_external___hdp-hadoop__namenode-conn___namenode_conn",
   :link_def_id=>2147489922,
   :parsed_port_name=>
    {:component=>"namenode-conn",
     :component_type=>"hdp-hadoop__namenode-conn",
     :link_def_ref=>"namenode_conn",
     :module=>"hdp-hadoop"},
   :node=>{:id=>2147519886, :display_name=>"slave"},
   :id=>2147519892,
   :connected=>nil,
   :display_name=>
    "component_external___hdp-hadoop__namenode-conn___namenode_conn"}]]
[:debug,
 XYZ::ServiceModule,
 "assemblies/hdfs/add-ons/slave.json",
 "slave",
 {"add_on_sub_assembly"=>"hdfs-slave",
  "description"=>"Adds slave node",
  "assembly"=>"hdfs",
  "port_links"=>
   [{"hdfs/master/hdp-hadoop::namenode/namenode_conn"=>
      "hdfs-slave/slave/hdp-hadoop::namenode-conn/namenode_conn"}]}]
=end
