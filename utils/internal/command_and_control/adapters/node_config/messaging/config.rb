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
module DTK
  module CommandAndControlAdapter
    class Messaging
      class Config
        require 'tempfile'
        require 'erubis'

        Lock = Mutex.new

        def self.install_script(node, bindings)
          create().install_script(node, bindings)
        end

        def install_script(node, bindings)
          all_bindings = install_script_bindings(node, bindings)
          erubis_object(install_script_erb()).result(all_bindings)
        end

        private

        def self.create
          type = (R8::Config[:arbiter][:auth_type] || :default).to_sym
          klass =
            case type
            when :ssh then Ssh
            else Default
            end
          klass.new(type)
        end

        def initialize(type)
          @type = type
        end

        def mcollective_config_erubis_object
          erubis_content = File.open(File.expand_path("auth/#{@type}/client.cfg.erb", File.dirname(__FILE__))).read
          erubis_object(erubis_content)
        end

        def logfile
          "/var/log/mcollective/#{Common::Aux.running_process_user()}/client.log"
        end

        def erubis_object(erubis_content)
          ::Erubis::Eruby.new(erubis_content)
        end

        class Default < self

          private

          def install_script_erb
            USER_DATA_SH_ERB
          end

          def install_script_bindings(_node, bindings)
            bindings
          end

          USER_DATA_SH_ERB = <<eos
cat << EOF >> /etc/mcollective/server.cfg
---
plugin.stomp.host = <%=node_config_server_host %>
EOF

cat << EOF > /etc/mcollective/facts.yaml
---
git-server: "<%=git_server_url %>"
EOF

ssh-keygen -f "/root/.ssh/known_hosts" -R <%=git_server_dns %>
cat << EOF >>/root/.ssh/known_hosts
<%=fingerprint %>
EOF

eos
        end

        class Ssh < self

          private

          def install_script_bindings(node, bindings)
            # TODO: clean up to have error checking
            ssh_remote_public_key = File.open(R8::Config[:arbiter][:ssh][:remote][:public_key], 'rb') { |f| f.read }
            ssh_remote_private_key = File.open(R8::Config[:arbiter][:ssh][:remote][:private_key], 'rb') { |f| f.read }
            ssh_local_public_key = File.open(R8::Config[:arbiter][:ssh][:local][:public_key], 'rb') { |f| f.read }
            pbuilderid = (node.pbuilderid() if node.get_iaas_type() == :physical)
            # order of merge does not matter; keys wont conflict
            bindings.merge(
              arbiter_ssh_remote_public_key: ssh_remote_public_key,
              arbiter_ssh_remote_private_key: ssh_remote_private_key,
              arbiter_ssh_local_public_key: ssh_local_public_key,
              # TODO: will generalize so not just puppet
              puppet_version: puppet_version(node),
              pbuilderid: pbuilderid,
              logstash_enable: R8::Config[:logstash][:enable],
              logstash_ca: get_logstash_ca,
              logstash_host: R8::Config[:logstash][:host],
              logstash_port: R8::Config[:logstash][:port],
              logstash_log_file_list: R8::Config[:logstash][:log_file_list],
              logstash_config_file_path: R8::Config[:logstash][:config_file_path],
              logstash_tag: R8::Config[:logstash][:tag],
              arbiter_update: R8::Config[:arbiter][:update],
              arbiter_branch: R8::Config[:arbiter][:branch],
              arbiter_topic: R8::Config[:arbiter][:topic],
              arbiter_queue: R8::Config[:arbiter][:queue],
              arbiter_restart: arbiter_restart(node),
              stomp_host: R8::Config[:stomp][:host],
              stomp_port: R8::Config[:stomp][:port],
              stomp_username: R8::Config[:stomp][:username],
              stomp_password: R8::Config[:stomp][:password]
              cloud_config_repo_upgrade: R8::Config[:cloud_config][:repo_upgrade]
              cloud_config_os_type: R8::Config[:cloud_config][:repo_upgrade][:os_type]
            )
          end

          def arbiter_restart(node)
            if OSNeedsRestart.include?(node[:os_type])
              true
            else
              if puppet_version = puppet_version(node)
                !puppet_version.empty?
              end
            end
          end
          OSNeedsRestart =  ['ubuntu', 'debian']

          def puppet_version(node)
            @puppet_version ||= {}
            @puppet_version[node.id] ||= get_puppet_version(node)
          end

          def get_puppet_version(node)
            node.attribute().puppet_version(raise_error_if_invalid: true) || ''
          end

          def install_script_erb
            USER_DATA_SH_ERB
          end

          def cloud_config_os_type
            os_type = R8::Config[:cloud_config][:repo_upgrade][:os_type]
            os_type = os_type.strip.delete(' ').split(',').map{ |x| x.to_sym }
          end

          def cloud_config_options_erb
            CLOUD_CONFIG_ERB
          end

          def get_logstash_ca
            File.open(R8::Config[:logstash][:ca_file_path], 'rb') { |f| f.read } if File.exist?(R8::Config[:logstash][:ca_file_path])
          end

          CLOUD_CONFIG_ERB = <<eos
#cloud-config
repo_upgrade: <%= repo_upgrade %>
eos

          USER_DATA_SH_ERB = <<eos
mkdir -p /etc/dtk/ssh
chmod 700 /etc/dtk/ssh

cat << EOF > /etc/dtk/ssh/arbiter
<%=arbiter_ssh_remote_private_key %>
EOF

cat << EOF > /etc/dtk/ssh/arbiter.pub
<%=arbiter_ssh_remote_public_key %>
EOF

cat << EOF > /etc/dtk/ssh/authorized_keys
<%=arbiter_ssh_local_public_key %>
EOF

ssh-keygen -f "/root/.ssh/known_hosts" -R <%=git_server_dns %>
cat << EOF >>/root/.ssh/known_hosts
<%=fingerprint %>
EOF

<% unless puppet_version.empty? %>
/opt/puppet-omnibus/embedded/bin/gem uninstall -aIx puppet
/opt/puppet-omnibus/embedded/bin/gem install puppet -v <%= puppet_version %> --no-rdoc --no-ri
<% end %>

cat << EOF > /etc/dtk/arbiter.cfg
stomp_url = <%= stomp_host %>
stomp_port = <%= stomp_port %>
stomp_username = <%= stomp_username %>
stomp_password = <%= stomp_password %>
arbiter_topic = <%= arbiter_topic %>
arbiter_queue = <%= arbiter_queue %>
git_server = "<%= git_server_url %>"
<% if pbuilderid %>
pbuilderid = <%= pbuilderid %>
<% else %>
# pbuidlerid =
<% end %>
private_key = /etc/dtk/ssh/arbiter
EOF

<% if arbiter_update %>
[ -x /usr/share/dtk/dtk-arbiter/update.sh ] && /usr/share/dtk/dtk-arbiter/update.sh <%=arbiter_branch %>
  <% if arbiter_restart %>
    [ -x /etc/init.d/dtk-arbiter ] && /etc/init.d/dtk-arbiter restart
  <% end %>
<% end %>

<% if logstash_enable %>
mkdir -p `dirname <%= logstash_config_file_path %>`
cat << EOF > /etc/logstash-forwarder/dtk.json
{
  "network": {
    "servers": [ "<%= logstash_host %>:<%= logstash_port %>" ],
    "timeout": 15,
    "ssl ca": "/etc/ssl/certs/logstash-forwarder.crt"
  },
  "files": [
    {
      "paths": <%= logstash_log_file_list -%>,
      "fields": { "type": "syslog", "tag": "<%= logstash_tag %>" }
    }
   ]
}
EOF

cat << EOF > /etc/ssl/certs/logstash-forwarder.crt
<%= logstash_ca %>
EOF

/etc/init.d/logstash-forwarder start
<% end %>
eos
        end
      end
    end
  end
end