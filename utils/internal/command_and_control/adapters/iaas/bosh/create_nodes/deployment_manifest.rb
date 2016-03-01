require 'erubis'

module DTK
  class CommandAndControlAdapter::Bosh::CreateNodes
    ##
    # Methods to generate the BOSH deployment manifest
    # API information can be found here: https://bosh.io/docs/director-api-v1.html
    #
    class DeploymentManifest
      def self.generate_yaml(create_nodes_proc)
        new(create_nodes_proc).generate_yaml
      end

      def initialize(create_nodes_proc)
        @create_nodes_proc = create_nodes_proc
      end
      private :initialize

      def generate_yaml
        ManifestTemplate.result(erb_values)
      end
      
      private

      def erb_values
        {
          dtk_server_host: '10.0.0.253',
          arbiter_ssh_private_key: arbiter_ssh_private_key,
          director_uuid: '3c7d47a0-26ec-44a5-a963-57125fa3c633',
          release: { name: 'dtk-agent2', version: '0+dev.10' }
        }
      end

      KeyIdentInYaml = 6 
      def arbiter_ssh_private_key
        private_key_path = R8::Config[:arbiter][:ssh][:remote][:private_key]
        # get file and add KeyIdentInYaml spaces in front of each line so at right place in yaml file
        File.open(private_key_path).inject(''){ |s, line| s + (" " * KeyIdentInYaml) + line } 
      end

      ManifestTemplate = Erubis::Eruby.new <<eos
---
name: dtk
director_uuid: <%= director_uuid %>

networks:
- name: default
  subnets:
  - cloud_properties:
      subnet: subnet-94b11ce2
    range: 10.0.0.0/24
  type: dynamic

resource_pools:
- name: default
  stemcell:
    name: bosh-aws-xen-ubuntu-trusty-go_agent
    version: latest
  network: default
  cloud_properties:
    instance_type: m1.small
    availability_zone: us-east-1a

compilation:
  workers: 2
  network: default
  reuse_compilation_vms: true
  cloud_properties:
    availability_zone: us-east-1a
    instance_type: m3.large

releases:
- name: <%= release[:name] %>
  version: <%= release[:version] %>

jobs:
- name: master
  instances: 1
  templates:
  - name: dtk-agent
  resource_pool: default
  networks:
  - name: default

update:
  canaries: 1
  canary_watch_time: 60000
  update_watch_time: 60000
  max_in_flight: 2

properties:
  dtk-agent:
    dtk_server_host: <%= dtk_server_host %>
    stomp_port: 6163
    stomp_username: dtk1
    stomp_password: marionette
    arbiter_topic: /topic/arbiter.dtk1.broadcast
    arbiter_queue: /queue/arbiter.dtk1.reply
    arbiter_ssh_private_key: |
<%= arbiter_ssh_private_key %>
    git_server_url: "ssh://git1@<%= dtk_server_host %>:2222"
    pbuilderid: i-d8eada58
eos
    end
  end
end
