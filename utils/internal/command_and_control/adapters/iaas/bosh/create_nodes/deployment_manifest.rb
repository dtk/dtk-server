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
          subnet_object: required_param(:subnet_object)
          ec2_size: 'm3.large',
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
  - range: <%= subnet_object.range %>
    gateway: <%= subnet_object.gateway %>
    reserved: <%= subnet_object.reserved_addresses %>
    static: <%= subnet_object.static_addresses %>
    cloud_properties:
      subnet: <%= subnet_object.aws_id %>

resource_pools:
- name: default
  stemcell:
    name: bosh-aws-xen-ubuntu-trusty-go_agent
    version: latest
  network: default
  cloud_properties:
    instance_type: <%= ec2_size %>
    availability_zone: <%= subnet_object.availability_zone %>

compilation:
  workers: 2
  network: default
  reuse_compilation_vms: true
  cloud_properties:
    availability_zone: <%= subnet_object.availability_zone %>
    instance_type: m3.large

releases:
- name: <%= release[:name] %>
  version: <%= release[:version] %>

jobs:
<% job_objects.each do |job_obj| -%>
- name: <%= job_obj.name %>
  instances: <%= job_obj.instances %>
  templates:
  - name: dtk-agent
  resource_pool: default
  networks:
  - name: default
<% end -%>

update:
  canaries: 1
  canary_watch_time: 60000
  update_watch_time: 60000
  max_in_flight: 2

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
