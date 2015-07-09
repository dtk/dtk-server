#TODO: plug in new method in Node::Template
module XYZ
  class LibraryNodes
    def self.get_hash(opts = {})
      ret = { 'node' => node_templates(opts), 'node_binding_ruleset' => node_binding_rulesets() }
      if opts[:in_library]
        { 'library' => { opts[:in_library] => ret } }
      else
        ret
      end
    end

    private

    def self.node_templates(opts = {})
       ret = {}
       nodes_info.each do |k, info|
         ret[k] = node_info(info, opts)
      end
      ret['null-node-template'] = null_node_info(opts)
      ret
     end

     def self.node_binding_rulesets
       ret_node_bindings_from_config_file() || Bindings
     end
     def self.nodes_info
       ret_nodes_info_from_config_file() || NodesInfoDefault
     end

     def self.ret_nodes_info_from_config_file
       unless content = ret_nodes_info_content_from_config_file()
         return nil
       end
       ret = {}
       content.each do |ami, info|
         info['sizes'].each do |ec2_size|
           size = ec2_size.split('.').last
           ref = "#{ami}-#{size}"
           ret[ref] = {
             os_identifier: info['type'],
             ami: ami,
             display_name: "#{info['display_name']} #{size}",
             os_type: info['os_type'],
             size: ec2_size,
             png: info['png']
           }
         end
       end
       ret
     end
     #      def self.ret_node_bindings_from_config_file()
     #        unless content = ret_nodes_info_content_from_config_file()
     #          return nil
     #        end
     #        ret = Hash.new
     #        content.each do |ami,info|
     #          info["sizes"].each do |ec2_size|
     #            size = ec2_size.split(".").last
     #            ref = "#{info["type"]}-#{size}"
     #            ret[ref] = {
     #              :type=>"clone",
     #              :os_type=>info["os_type"],
     #              :os_identifier=>info["type"],
     #              :rules=>
     #              [{:conditions=>{:type=>"ec2_image", :region=>info["region"]},
     #                 :node_template=>{
     #                   :type=>"ec2_image",:image_id=>ami,
     #                   :size=>ec2_size,
     #                   :region=>info["region"]
     #                 }
     #               }]
     #            }
     #          end
     #        end
     #        ret
     #      end
     def self.ret_node_bindings_from_config_file
       unless content = ret_nodes_info_content_from_config_file()
         return nil
       end
       ret = {}
       content.each do |ami, info|
         info['sizes'].each do |ec2_size|
           size = ec2_size.split('.').last
           ref = "#{info['type']}-#{size}"
           pntr = ret[ref] ||= {
             type: 'clone',
             os_type: info['os_type'],
             os_identifier: info['type']
           }
           pntr[:rules] = Rules.add(pntr[:rules], info, ami, ec2_size)
         end
       end
       ret
     end
     class Rules
       def self.add(rules, info, ami, ec2_size)
         new_el = { conditions: Conditions.new(info), node_template: NodeTemplate.new(info, ami, ec2_size) }
         if rules
           add_element?(rules, new_el)
         else
           [new_el]
         end
       end

       private

       def self.add_element?(rules, new_el)
         rules.each do |rule|
           if rule[:conditions].equal?(new_el[:conditions])
             Log.error('Unexpected that have matching conditions; skipping')
             return rules
           end
         end
         rules + [new_el]
       end

       class Conditions < Hash
         def initialize(info)
           replace(type: 'ec2_image', region: info['region'])
         end

         def equal?(rc)
           self[:type] == rc[:type] && self[:region] == rc[:region]
         end
       end
       class NodeTemplate < Hash
         def initialize(info, ami, ec2_size)
           replace(
                   type: 'ec2_image',
                   image_id: ami,
                   size: ec2_size,
                   region: info['region']
           )
         end
       end
     end

     def self.ret_nodes_info_content_from_config_file
       return @content if @content
       config_base = Configuration.instance.default_config_base()
       node_config_file  = "#{config_base}/nodes_info.json"
       return nil unless File.file?(node_config_file)
       @content = JSON.parse(File.open(node_config_file).read)['nodes_info']
     end

   def self.node_info(info, opts = {})
     ret = {
       'os_type' => info[:os_type],
       'os_identifier' => info[:os_identifier],
       'type' => 'image',
       'display_name' => info[:display_name],
       'external_ref' => {
         'image_id' => info[:ami],
         'type' => 'ec2_image' }.merge(info[:ami] ? { 'size' => info[:size] } : {}),
       'ui' =>           { 'images' =>             { 'tiny' => '', 'tnail' => info[:png], 'display' => info[:png] } },
       'attribute' => {
          'host_addresses_ipv4' =>             { 'required' => false,
                                                 'read_only' => true,
                                                 'is_port' => true,
                                                 'cannot_change' => false,
                                                 'data_type' => 'json',
                                                 'value_derived' => [nil],
                                                 'semantic_type_summary' => 'host_address_ipv4',
                                                 'display_name' => 'host_addresses_ipv4',
                                                 'dynamic' => true,
                                                 'hidden' => true,
                                                 'semantic_type' => { ':array' => 'host_address_ipv4' }
          },
          'fqdn' =>             { 'required' => false,
                                  'read_only' => true,
                                  'is_port' => true,
                                  'cannot_change' => false,
                                  'data_type' => 'string',
                                  'display_name' => 'fqdn',
                                  'dynamic' => true,
                                  'hidden' => true
          },
          'node_components' =>             { 'required' => false,
                                             'read_only' => true,
                                             'is_port' => true,
                                             'cannot_change' => false,
                                             'data_type' => 'json',
                                             'display_name' => 'node_components',
                                             'dynamic' => true,
                                             'hidden' => true
          }
       },
       'node_interface' =>        { 'eth0' => { 'type' => 'ethernet', 'display_name' => 'eth0' } }
     }

     if node_binding_rs_id = node_info_binding_ruleset_id(info, opts)
       ret['*node_binding_rs_id'] =  node_binding_rs_id
     end
     ret
   end

   def self.null_node_info(opts = {})
     ret = node_info({ display_name: 'null-node-template' }, opts)
     (ret['attribute'] ||= {}).merge!(null_node_info_attributes(opts))
     ret
   end

   def self.null_node_info_attributes(_opts = {})
     {
       'os_identifier' => {
         'required' => true,
         'data_type' => 'string',
         'display_name' => 'os_identifier'
       },
       'memory_size' => {
         'required' => false,
         'data_type' => 'string',
         'display_name' => 'memory_size'
       }
     }
   end

   def self.node_info_binding_ruleset_id(info, opts = {})
     node_binding_rulesets().each do |k, v|
       v[:rules].each_with_index do |r, _i|
         nt = r[:node_template]
         if info[:ami] == nt[:image_id] && info[:size] == nt[:size]
           ret = "/node_binding_ruleset/#{k}"
           if opts[:in_library]
             return "/library/#{opts[:in_library]}#{ret}"
           else
             return ret
           end
         end
       end
     end
     nil
   end

   def self.add_monitoring_info!(_info)
=begin
# TODO: not used yet
     (info["attribute"] ||= Hash.new)["monitoring_item"] =
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
=end
   end

     # TODO: deprecate below
     NodesInfoDefault = {
       ## for EU west
       'ami-b7d4eec3-small' => {
         ami: 'ami-b7d4eec3',
         display_name: 'CentOS 5.6 small',
         os_type: 'centos',
         size: 'm1.small',
         png: 'centos.png'
       },
       'ami-b7d4eec3-micro' => {
         ami: 'ami-b7d4eec3',
         display_name: 'CentOS 5.6 micro',
         os_type: 'centos',
         size: 't1.micro',
         png: 'centos.png'
       },
       'ami-5949732d-micro' => {
         ami: 'ami-5949732d',
         display_name: 'RH5.7 64 micro',
         os_type: 'redhat',
         size: 't1.micro',
         png: 'redhat.png'
       },
       'ami-5949732d-medium' => {
         ami: 'ami-5949732d',
         display_name: 'RH5.7 64 medium',
         os_type: 'redhat',
         size: 'm1.medium',
         png: 'redhat.png'
       },
       'ami-5949732d-large' => {
         ami: 'ami-5949732d',
         display_name: 'RH5.7 64 large',
         os_type: 'redhat',
         size: 'm1.large',
         png: 'redhat.png'
       },

       ## for US east
       'ami-9bce1ef2-small' => {
         ami: 'ami-9bce1ef2',
         display_name: 'CentOS 5.6 small',
         os_type: 'centos',
         size: 'm1.small',
         png: 'centos.png'
       },
       'ami-9bce1ef2-micro' => {
         ami: 'ami-9bce1ef2',
         display_name: 'CentOS 5.6 micro',
         os_type: 'centos',
         size: 't1.micro',
         png: 'centos.png'
       },
       'ami-0f42f666-micro' => {
         ami: 'ami-0f42f666',
         display_name: 'RH5.7 64 micro',
         os_type: 'redhat',
         size: 't1.micro',
         png: 'redhat.png'
       },
       'ami-0f42f666-medium' => {
         ami: 'ami-0f42f666',
         display_name: 'RH5.7 64 medium',
         os_type: 'redhat',
         size: 'm1.medium',
         png: 'redhat.png'
       },
       'ami-0f42f666-large' => {
         ami: 'ami-0f42f666',
         display_name: 'RH5.7 64 large',
         os_type: 'redhat',
         size: 'm1.large',
         png: 'redhat.png'
       },
       'ami-e7b1618e-small' => {
         ami: 'ami-e7b1618e',
         display_name: 'Natty small',
         os_type: 'ubuntu',
         size: 'm1.small',
         png: 'ubuntu.png'
       },
       'ami-e7b1618e-micro' => {
         ami: 'ami-e7b1618e',
         display_name: 'Natty micro',
         os_type: 'ubuntu',
         size: 't1.micro',
         png: 'ubuntu.png'
       }
     }
Bindings = { 'centos-5.6-small' => { type: 'clone',
                                     os_type: 'centos',
                                     rules: [{ conditions: { type: 'ec2_image', region: 'us-east-1' },
                                               node_template: { type: 'ec2_image',
                                                                image_id: 'ami-9bce1ef2',
                                                                size: 'm1.small',
                                                                region: 'us-east-1' } }] },
             'rh5.7-64-large' => { type: 'clone',
                                   os_type: 'redhat',
                                   rules: [{ conditions: { type: 'ec2_image', region: 'us-east-1' },
                                             node_template: { type: 'ec2_image',
                                                              image_id: 'ami-0f42f666',
                                                              size: 'm1.large',
                                                              region: 'us-east-1' } }] },
             'natty-micro' => { type: 'clone',
                                os_type: 'ubuntu',
                                rules: [{ conditions: { type: 'ec2_image', region: 'us-east-1' },
                                          node_template: { type: 'ec2_image',
                                                           image_id: 'ami-e7b1618e',
                                                           size: 't1.micro',
                                                           region: 'us-east-1' } }] },
             'natty-small' => { type: 'clone',
                                os_type: 'ubuntu',
                                rules: [{ conditions: { type: 'ec2_image', region: 'us-east-1' },
                                          node_template: { type: 'ec2_image',
                                                           image_id: 'ami-e7b1618e',
                                                           size: 'm1.small',
                                                           region: 'us-east-1' } }] },
             'centos-5.6-micro' => { type: 'clone',
                                     os_type: 'centos',
                                     rules: [{ conditions: { type: 'ec2_image', region: 'us-east-1' },
                                               node_template: { type: 'ec2_image',
                                                                image_id: 'ami-9bce1ef2',
                                                                size: 't1.micro',
                                                                region: 'us-east-1' } }] },
             'rh5.7-64-micro' => { type: 'clone',
                                   os_type: 'redhat',
                                   rules:        [
        { conditions: { type: 'ec2_image', region: 'us-east-1' },
          node_template: { type: 'ec2_image',
                           image_id: 'ami-0f42f666',
                           size: 't1.micro',
                           region: 'us-east-1' } },
        { conditions: { type: 'ec2_image', region: 'eu-west-1' },
          node_template: { type: 'ec2_image',
                           image_id: 'ami-5949732d',
                           size: 't1.micro',
                           region: 'eu-west-1' } }
       ]
     },
             'rh5.7-64-medium' => { type: 'clone',
                                    os_type: 'redhat',
                                    rules:        [
        { conditions: { type: 'ec2_image', region: 'us-east-1' },
          node_template: { type: 'ec2_image',
                           image_id: 'ami-0f42f666',
                           size: 'm1.medium',
                           region: 'us-east-1' } },
        { conditions: { type: 'ec2_image', region: 'eu-west-1' },
          node_template: { type: 'ec2_image',
                           image_id: 'ami-5949732d',
                           size: 'm1.medium',
                           region: 'eu-west-1' } }
       ]
     }
   }
   Bindings.each { |k, v| v[:display_name] = k.gsub(/-/, ' ') }
  end
end
