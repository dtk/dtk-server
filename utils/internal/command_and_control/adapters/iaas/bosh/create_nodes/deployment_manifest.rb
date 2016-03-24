require 'erubis'

module DTK; class CommandAndControl::IAAS; class Bosh
  class CreateNodes
    ##
    # Methods to generate the BOSH deployment manifest
    # API information can be found here: https://bosh.io/docs/director-api-v1.html
    #
    class DeploymentManifest
      def self.generate_yaml(params)
        new(params).generate_yaml
      end

      def initialize(params)
        @params = params
      end
      private :initialize

      def generate_yaml
        ManifestTemplate.result(erb_values)
      end
      
      private

      def erb_values
        {
          dtk_server_host: R8::Config[:stomp][:host], 
          stomp_port: R8::Config[:stomp][:port], 
          repo_git_port: R8::Config[:repo][:git][:port], 
          arbiter_ssh_private_key: arbiter_ssh_private_key,
          director_uuid: required_param(:director_uuid),
          release: required_param(:release),
          deployment_name: required_param(:deployment_name),
          job_objects: required_param(:job_objects),
          repo_user: R8::Config[:repo][:git][:server_username],
          bosh_subnet: required_param(:bosh_subnet),
          # TODO: remove hard coded
          ec2_size: 'm3.large',
          # stemcell: { name: 'bosh-aws-xen-hvm-centos-7-go_agent', version: 'latest' },
          stemcell: { name: 'bosh-aws-xen-ubuntu-trusty-go_agent', version: 'latest' },
          max_in_flight: 10
        }
      end

      def param(key)
        @params[key]
      end
      def required_param(key)
        unless @params.has_key?(key)
          fail Error.new("Missing required param '#{key}'")
        end
        @params[key]
      end

      KeyIdentInYaml = 6 
      def arbiter_ssh_private_key
        private_key_path = R8::Config[:arbiter][:ssh][:remote][:private_key]
        # get file and add KeyIdentInYaml spaces in front of each line so at right place in yaml file
        File.open(private_key_path).inject(''){ |s, line| s + (" " * KeyIdentInYaml) + line } 
      end

      ManifestTemplate = Erubis::Eruby.new <<eos
---
name: <%= deployment_name %>
director_uuid: <%= director_uuid %>

networks:
- name: default
  type: manual
  subnets:
  - range: <%= bosh_subnet.range %>
    gateway: <%= bosh_subnet.gateway %>
    reserved: <%= bosh_subnet.reserved_addresses %>
<% if bosh_subnet.static_addresses? -%>
    static: <%= bosh_subnet.static_addresses? %>
<% end -%>
    cloud_properties:
      subnet: <%= bosh_subnet.vpc_subnet %>

resource_pools:
- name: default
  stemcell:
    name: <%= stemcell[:name] %>
    version: <%= stemcell[:version] %>
  network: default
  cloud_properties:
    instance_type: <%= ec2_size %>
    availability_zone: <%= bosh_subnet.ec2_availability_zone %>
    root_disk:
      size: 20000
      type: gp2
compilation:
  workers: 2
  network: default
  reuse_compilation_vms: true
  cloud_properties:
    availability_zone: <%= bosh_subnet.ec2_availability_zone %>
    instance_type: m3.large

releases:
- name: <%= release[:name] %>
  version: <%= release[:version] %>

jobs:
<% job_objects.each do |job_obj| -%>
- name: <%= job_obj.name %>
  instances: <%= job_obj.num_instances %>
  templates:
  - name: <%= release[:name] %>
  resource_pool: default
  networks:
  - name: default
<% if job_obj.static_ips?  -%>
    static_ips: <%= job_obj.static_ips? %>
<% end -%>
<% end -%>

update:
  canaries: 1
  canary_watch_time: 60000
  update_watch_time: 60000
  max_in_flight: <%= max_in_flight %>

properties:
  dtk-agent:
    dtk_server_host: <%= dtk_server_host %>
    git_server_url: "ssh://<%= repo_user %>@<%= dtk_server_host %>:<%= repo_git_port %>"
    stomp_port: <%= stomp_port %>
    stomp_username: dtk1
    stomp_password: marionette
    arbiter_topic: /topic/arbiter.dtk1.broadcast
    arbiter_queue: /queue/arbiter.dtk1.reply
    arbiter_ssh_private_key: |
<%= arbiter_ssh_private_key %>
eos
    end
  end
end; end; end
