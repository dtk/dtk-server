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
        ManifestTemplate.result(arbiter_ssh_private_key: '')
      end


      ManifestTemplate = Erubis::Eruby.new <<eos
---
name: dtk
director_uuid: bf814f44-4319-4841-828a-fa5c624dd47f

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
- name: dtk-agent2
  version: 0+dev.5

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
    dtk_server_host: 10.0.0.253
    stomp_port: 6163
    stomp_username: dtk1
    stomp_password: marionette
    arbiter_topic: /topic/arbiter.dtk1.broadcast
    arbiter_queue: /queue/arbiter.dtk1.reply
    arbiter_ssh_private_key: |
<%= arbiter_ssh_private_key %>
    git_server_url: "ssh://git1@10.0.0.253:2222"
    pbuilderid: i-d8eada58
eos
    end
  end
end
