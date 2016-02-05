#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# TODO: this is just temp step; just cut and past of conf files
# simpler syntactic form

module R8
  class ConfigHash < ::DTK::HashObject::AutoViv
    # TODO: for putting in hooks to better report on config var access errors
    def is_development_mode?
      self[:debug][:development_mode]
    end

  end

  Config = ConfigHash.create()
  # TODO: change R8 to DTK::Server and get rid of EnvironmentConfig
  def self.app_user_home
    ::DTK::Common::Aux.running_process_home_dir()
  end

  def self.app_user
    ::DTK::Common::Aux.running_process_user()
  end

  # TODO: this wil be moved
  module EnvironmentConfig
    CommandAndControlMode = 'mcollective'
    GitExecutable = '/usr/bin/git'
    SourceExternalRepoDir = "#{R8.app_user_home()}/core-cookbooks"
  end
end

R8::Config[:puppet][:parser][:parse_just_signatures] = true

R8::Config[:dsl][:service][:integer_version][:default] = 2
R8::Config[:dsl][:service][:format_type][:default] = 'yaml'

R8::Config[:dsl][:component][:integer_version][:default] = 2
R8::Config[:dsl][:component][:format_type][:default] = 'yaml'

R8::Config[:log][:level] = 'debug'

R8::Config[:file_asset][:cache_content] = false

R8::Config[:dns][:r8][:domain] = 'r8network.com'
R8::Config[:command_and_control][:node_config][:type] = 'stomp'
# R8::Config[:command_and_control][:iaas][:type] = "ec2__mock"
# this is server abh is using but wil be deprecated R8::Config[:repo][:remote][:host] = "ec2-174-129-28-204.compute-1.amazonaws.com"

# MOD_RESTRUCT: TODO: may decide to allways have this set one way
R8::Config[:repo][:workspace][:use_local_clones] = true

R8::Config[:repo][:remote][:default_namespace] = 'r8'
R8::Config[:repo][:local][:default_namespace] = 'local'
# R8::Config[:repo][:type] = "mock"
# R8::Config[:benchmark] = %w{create_from_hash create_from_select} # get_objects_just_dataset} # :all
R8::Config[:git_server_on_dtk_server] = true

R8::Config[:ec2][:fog_credentials_path] = "#{R8.app_user_home()}/.fog"
R8::Config[:ec2][:keypair] = 'rich-east'
R8::Config[:ec2][:security_group] = 'default'
R8::Config[:ec2][:regions] = ['us-east-1', 'us-west-1', 'us-west-2', 'eu-west-1', 'sa-east-1', 'ap-northeast-1', 'ap-southeast-1', 'ap-southeast-2']
R8::Config[:ec2][:iaas_type][:supported] = ['ec2']
# R8::Config[:ec2][:name_tag][:format] = "${tenant}:${target}:${user}:${assembly}:${node}"
R8::Config[:ec2][:name_tag][:format] = 'dtk:${assembly}:${node}'
# VPC settings
R8::Config[:ec2][:vpc_enable] = false
# instances will be launched in this subnet
R8::Config[:ec2][:vpc][:subnet_id] = ''
# override subnet setting
R8::Config[:ec2][:vpc][:associate_public_ip] = true
# set the VPC security group
R8::Config[:ec2][:vpc][:security_group] = 'default'
R8::Config[:ec2][:service_instance][:ttl] = 3

# Application defaults
R8::Config[:application_name] = 'application'
R8::Config[:default_language] = 'en.us'
R8::Config[:default_layout] = 'default'

# Encryption info
R8::Config[:encryption][:password_salt] = nil
R8::Config[:encryption][:cookie_salt] = nil

R8::Config[:server_public_dns] = ::DTK::Common::Aux.get_ec2_public_dns()
R8::Config[:server_port] = 7000

R8::Config[:login][:path] = '/xyz/user/login'
R8::Config[:login][:resgister] = '/xyz/user/register'
# TODO: below is stub
R8::Config[:login][:redirect] = '/xyz/ide/index'

# Target related config params
R8::Config[:dtk][:target][:builtin][:node_limit] = 5

# Database related config params
R8::Config[:database][:hostname] = '127.0.0.1'
R8::Config[:database][:user] = 'postgres'
R8::Config[:database][:pass] = 'bosco'
R8::Config[:database][:name] = 'db_main'
R8::Config[:database][:type] = 'postgres'

# Workflow related parameters
R8::Config[:workflow][:type] = 'ruote'
# R8::Config[:workflow][:type] = "simple"

# TODO: will deprecate "GUARDS" and possible "TOTAL_ORDER"
# R8::Config[:workflow][:temporal_coordination][:inter_node] = "GUARDS"
# R8::Config[:workflow][:temporal_coordination][:intra_node] = "TOTAL_ORDER"
R8::Config[:workflow][:temporal_coordination][:inter_node] = 'STAGES'
R8::Config[:workflow][:temporal_coordination][:intra_node] = 'STAGES'
R8::Config[:workflow][:install_agents][:timeout] = '300'
R8::Config[:workflow][:install_agents][:threads] = '10'

R8::Config[:repo].set?(:base_directory, "#{R8.app_user_home()}/r8server-repo")
R8::Config[:repo].set?(:type, 'git')
R8::Config[:repo][:git][:server_type] = 'gitolite'
R8::Config[:repo][:git][:server_username] = 'git'
R8::Config[:repo][:git][:port] = 22

R8::Config[:repo][:git][:gitolite][:admin_directory] = "#{R8.app_user_home()}/r8_gitolite_admin"

# for remote repo that attach to
R8::Config[:repo][:remote][:rest_port] = 7000
R8::Config[:repo][:remote][:secure_connection] = true
R8::Config[:repo][:remote][:git_user] = 'git'
R8::Config[:repo][:remote][:new_client]  = false
R8::Config[:repo][:remote][:tenant_name] = nil


R8::Config[:node_agent_git_clone][:mode] = "off"
R8::Config[:node_agent_git_clone][:local_dir] = "#{R8::Config[:repo][:base_directory]}/dtk-node-agent"
R8::Config[:node_agent_git_clone][:remote_url] = 'https://github.com/rich-reactor8/dtk-node-agent.git'
R8::Config[:node_agent_git_clone][:branch] = 'stable'

# TODO: temp until port over to new way of dynamically loading mc agents
R8::Config[:node_agent_git_clone][:no_delay_needed_on_server] = false

# Properties for DTK Action Agent sync via DTK Node Agent (Dev Manager)
R8::Config[:action_agent_sync][:enabled] = false
R8::Config[:action_agent_sync][:remote_url] = 'https://github.com/rich-reactor8/dtk-action-agent.git'
R8::Config[:action_agent_sync][:branch] = 'stable'

# Command and control related parameters
# R8::Config[:command_and_control][:node_config].set?(:type,"mcollective")
R8::Config[:command_and_control][:node_config].set?(:type, 'mcollective__mock')

# TODO: put in provisions to have multiple iias providers at same time
R8::Config[:command_and_control][:iaas].set?(:type, 'ec2')
R8::Config[:command_and_control][:iaas][:ec2][:default_image_size] = 't1.micro'
# R8::Config[:command_and_control][:iaas].set?(:type,"ec2__mock")

# optional timer plug
# R8::Config[:timer][:type] = "debug_timeout" # "system_timer"

# these are used in template.rb and view.rb
# R8::Config[:sys_root_path] = "C:/webroot/R8Server"

# Link related config params
R8::Config[:links][:default_type] = 'fullBezier'
R8::Config[:links][:default_style] = []
R8::Config[:links][:default_style] = [
  { strokeStyle: '#25A3FC', lineWidth: 3, lineCap: 'round' },
  { strokeStyle: '#63E4FF', lineWidth: 1, lineCap: 'round' }
]

# TODO: eventually cleanup to be more consise of use between root, path,dir, etc
R8::Config[:sys_root_path] = SYSTEM_ROOT_PATH
R8::Config[:app_root_path] = "#{R8::Config[:sys_root_path]}/#{R8::Config[:application_name]}"
R8::Config[:app_cache_root] = "#{R8::Config[:sys_root_path]}/cache/#{R8::Config[:application_name]}"
R8::Config[:system_views_dir] = "#{R8::Config[:sys_root_path]}/system/view"
R8::Config[:meta_templates_root] = "#{R8::Config[:app_root_path]}/meta"
# TODO: probably converge meta_templates references into meta_base and remove
R8::Config[:meta_base_dir] = "#{R8::Config[:app_root_path]}/meta"
R8::Config[:i18n_base_dir] = "#{R8::Config[:app_root_path]}/i18n"
R8::Config[:dev_mode] = true

R8::Config[:base_views_dir] = "#{R8::Config[:app_root_path]}/view"

R8::Config[:js_file_dir] = "#{R8::Config[:app_root_path]}/public/js"
R8::Config[:css_file_dir] = "#{R8::Config[:app_root_path]}/public/css"

R8::Config[:js_file_write_path] = "#{R8::Config[:app_root_path]}/public/js/cache"
R8::Config[:js_templating_on] = false

R8::Config[:editor_file_path] = "#{R8::Config[:app_root_path]}/editor"
R8::Config[:config_file_path] = "#{R8::Config[:app_root_path]}/config_upload"

R8::Config[:page_limit] = 20

R8::Config[:session][:timeout][:disabled] = false
R8::Config[:session][:cookie][:disabled] = false
R8::Config[:session][:timeout][:hours] = 4

# Arbiter SSH keys path
# expected to be at ~/rsa_identity_dir/
R8::Config[:rsa_idenitity_dir] = "#{R8.app_user_home()}/rsa_identity_dir"
R8::Config[:arbiter][:ssh][:remote][:public_key] = "#{R8::Config[:rsa_idenitity_dir]}/arbiter_remote.pub"
R8::Config[:arbiter][:ssh][:remote][:private_key] = "#{R8::Config[:rsa_idenitity_dir]}/arbiter_remote"
R8::Config[:arbiter][:ssh][:local][:public_key] = "#{R8::Config[:rsa_idenitity_dir]}/arbiter_local.pub"
R8::Config[:arbiter][:ssh][:local][:private_key] = "#{R8::Config[:rsa_idenitity_dir]}/arbiter_local"
R8::Config[:arbiter][:ssh][:local][:authorized_keys] = "#{R8::Config[:rsa_idenitity_dir]}/authorized_keys"

# TO-DO: update to reflect arbiter changes (like introducing queues)
R8::Config[:arbiter][:id] = 'arbiter'
R8::Config[:arbiter][:topic] = "/topic/arbiter.#{R8.app_user}.broadcast"
R8::Config[:arbiter][:queue] = "/queue/arbiter.#{R8.app_user}.reply"
R8::Config[:arbiter][:update] = true
R8::Config[:arbiter][:branch] = 'stable'
R8::Config[:arbiter][:auth_type] = 'ssh'

R8::Config[:stomp][:host] = ::DTK::Common::Aux.get_ec2_public_dns()
R8::Config[:stomp][:port] = '6163'
R8::Config[:stomp][:username] = R8.app_user
R8::Config[:stomp][:password] = 'marionette'

# Remote Repo (Repoman)
R8::Config[:remote_repo][:authentication] = true
# public user credentials, we use ore-hashed password
R8::Config[:remote_repo][:public][:username] = 'dtk-public-user'
R8::Config[:remote_repo][:public][:password] = nil

# Debug flags
R8::Config[:debug][:development_mode] = false
R8::Config[:debug][:show_backtrace] = false
R8::Config[:debug][:arbiter] = false

# Grit config
R8::Config[:grit][:debug] = false
R8::Config[:grit][:git_timeout] = 120
R8::Config[:grit][:git_max_size] = 10 * 5242880 # 50MB

# Puppet version
R8::Config[:puppet][:version] = ''

# Logstash-forwarder configuration
# assumes logstash-forwarder is installed on nodes
R8::Config[:logstash][:enable] = false
R8::Config[:logstash][:ca_file_path] = "#{R8::Config[:rsa_idenitity_dir]}/logstash-forwarder.crt"
R8::Config[:logstash][:log_file_list] = ['/var/log/puppet/last.log', '/var/log/mcollective.log']
R8::Config[:logstash][:host] = 'logstash.internal.r8network.com'
R8::Config[:logstash][:port] = '5000'
# the config files are read by default from /etc/logstash-forwarder
R8::Config[:logstash][:config_file_path] = '/etc/logstash-forwarder/dtk.json'
R8::Config[:logstash][:tag] = R8.app_user