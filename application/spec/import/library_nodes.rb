module XYZ
  class LibraryNodes
    def self.get()
      #TOIDO: deprecate the nodes and just have node being rules
      {"library"=> {"public"=> {"node"=> nodes, "node_binding_ruleset" => node_binding_rulesets}}}
    end
   private
     def self.nodes()
       ret = Hash.new
       NodesInfo.each do |k,info|
         ret[k] = node_info(info)
       end
       ret
     end
     NodesInfo = {
       "ami-9bce1ef2-small"=> {
         :ami => "ami-9bce1ef2",
         :display_name =>"CentOS 5.6 small",
         :os_type =>"centos",
         :size => "m1.small",
         :png => "centos.png"
       },
       "ami-9bce1ef2-micro"=> {
         :ami => "ami-9bce1ef2",
         :display_name =>"CentOS 5.6 micro",
         :os_type =>"centos",
         :size => "t1.micro",
         :png => "centos.png"
       },
       "ami-6425800d-micro"=> {
         :ami => "ami-6425800d",
         :display_name => "RH5.7 64 micro",
         :os_type =>"redhat",
         :size => "t1.micro",
         :png => "redhat.png"
       },
       "ami-6425800d-medium"=> {
         :ami => "ami-6425800d",
         :display_name => "RH5.7 64 medium",
         :os_type =>"redhat",
         :size => "m1.medium",
         :png => "redhat.png"
       },
       "ami-6425800d-large"=> {
         :ami => "ami-6425800d",
         :display_name => "RH5.7 64 large",
         :os_type =>"redhat",
         :size => "m1.large",
         :png => "redhat.png"
       },
       "ami-e7b1618e-small"=> {
         :ami => "ami-e7b1618e",
         :display_name => "Natty small",
         :os_type =>"ubuntu",
         :size => "m1.small",
         :png => "ubuntu.png"
       },
       "ami-e7b1618e-micro"=> {
         :ami => "ami-e7b1618e",
         :display_name => "Natty small",
         :os_type =>"ubuntu",
         :size => "t1.micro",
         :png => "ubuntu.png"
       }
     }
   def self.node_info(info)
     {"os_type"=>info[:os_type],
       "type"=>"image",
       "display_name"=> info[:display_name],
       "external_ref"=>{
         "image_id"=>info[:ami],
         "type"=>"ec2_image"}.merge(info[:ami] ? {"size"=>info[:size]} : {}),
        "ui"=>
          {"images"=>
            {"tiny"=>"", "tnail"=>info[:png], "display"=>info[:png]}},
         "attribute"=> {
          "host_addresses_ipv4"=>
            {"required"=>false,
             "read_only"=>true,
             "is_port"=>true,
             "cannot_change"=>false,
             "data_type"=>"json",
             "value_derived"=>[nil],
             "semantic_type_summary"=>"host_address_ipv4",
             "display_name"=>"host_addresses_ipv4",
             "dynamic"=>true,
             "hidden"=>false,
             "semantic_type"=>{":array"=>"host_address_ipv4"}
          },
          "fqdn"=>
            {"required"=>false,
             "read_only"=>true,
             "is_port"=>true,
             "cannot_change"=>false,
             "data_type"=>"string",
             "display_name"=>"fqdn",
             "dynamic"=>true,
             "hidden"=>false,
          },
          "node_components"=>
            {"required"=>false,
             "read_only"=>true,
             "is_port"=>true,
             "cannot_change"=>false,
             "data_type"=>"json",
             "display_name"=>"node_components",
             "dynamic"=>true,
             "hidden"=>false,
          }
         },
         "node_interface"=>
          {"eth0"=>{"type"=>"ethernet", "display_name"=>"eth0"}},
         "monitoring_item"=>
          {"check_ping"=>
            {"enabled"=>true,
             "description"=>"ping",
             "display_name"=>"check_ping"},
           "check_mem"=>
            {"enabled"=>true,
             "description"=>"Free Memory",
             "display_name"=>"check_mem"},
           "check_local_procs"=>
            {"enabled"=>true,
             "description"=>"Processes",
             "display_name"=>"check_local_procs"},
           "check_all_disks"=>
            {"enabled"=>true,
             "description"=>"Free Space All Disks",
             "display_name"=>"check_all_disks"},
           "check_memory_profiler"=>
            {"enabled"=>true,
             "description"=>"Memory Profiler",
             "display_name"=>"check_memory_profiler"},
           "check_iostat"=>
            {"enabled"=>true,
             "description"=>"Iostat",
             "display_name"=>"check_iostat"},
           "check_ssh"=>
            {"enabled"=>true,
             "description"=>"SSH",
             "display_name"=>"check_ssh"}
         }
       }
   end
   def self.node_binding_rulesets()
{"centos-5.6-small"=>{:type=>"clone",
  :rules=>[{:conditions=>{:type=>"ec2_image", :region=>"us-east-1"},
    :node_template=>{:type=>"ec2_image",
     :image_id=>"ami-9bce1ef2",
     :size=>"m1.small",
     :region=>"us-east-1"}}]},
 "rh5.7-64-large"=>{:type=>"clone",
  :rules=>[{:conditions=>{:type=>"ec2_image", :region=>"us-east-1"},
    :node_template=>{:type=>"ec2_image",
     :image_id=>"ami-6425800d",
     :size=>"m1.large",
     :region=>"us-east-1"}}]},
 "natty-small"=>{:type=>"clone",
  :rules=>[{:conditions=>{:type=>"ec2_image", :region=>"us-east-1"},
    :node_template=>{:type=>"ec2_image",
     :image_id=>"ami-e7b1618e",
     :size=>"t1.micro",
     :region=>"us-east-1"}}]},
 "centos-5.6-micro"=>{:type=>"clone",
  :rules=>[{:conditions=>{:type=>"ec2_image", :region=>"us-east-1"},
    :node_template=>{:type=>"ec2_image",
     :image_id=>"ami-9bce1ef2",
     :size=>"t1.micro",
     :region=>"us-east-1"}}]},
 "rh5.7-64-micro"=>{:type=>"clone",
  :rules=>[{:conditions=>{:type=>"ec2_image", :region=>"us-east-1"},
    :node_template=>{:type=>"ec2_image",
     :image_id=>"ami-6425800d",
     :size=>"t1.micro",
     :region=>"us-east-1"}}]},
 "rh5.7-64-medium"=>{:type=>"clone",
  :rules=>[{:conditions=>{:type=>"ec2_image", :region=>"us-east-1"},
    :node_template=>{:type=>"ec2_image",
     :image_id=>"ami-6425800d",
     :size=>"m1.medium",
     :region=>"us-east-1"}}]}}
   end
  end
end

