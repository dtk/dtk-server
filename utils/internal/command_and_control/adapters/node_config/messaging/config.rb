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
          type = (R8::Config[:mcollective][:auth_type] || :default).to_sym
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
              stomp_port: R8::Config[:arbiter][:port],
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
              arbiter_username: R8::Config[:arbiter][:username],
              arbiter_password: R8::Config[:arbiter][:password]
            )
          end

          def mcollective_restart(node)
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

          def get_logstash_ca
            File.open(R8::Config[:logstash][:ca_file_path], 'rb') { |f| f.read } if File.exist?(R8::Config[:logstash][:ca_file_path])
          end

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

cat << EOF > /etc/dtk-arbiter.cfg
stomp_url = <%=node_config_server_host %>
stomp_port = <%=stomp_port %>
stomp_username = <%=arbiter_username %>
stomp_password = <%=arbiter_password %>
arbiter_topic = <%=arbiter_topic %>
arbiter_queue = <%=arbiter_queue %>
git_server = "<%=git_server_url %>"
pbuilderid = <%= pbuilderid %>
private_key = /etc/dtk/ssh/arbiter
<% end %>
EOF

<% if arbiter_update %>
[ -x /usr/share/dtk/dtk-arbiter/update.sh ] && /usr/share/dtk/dtk-arbiter/update.sh <%=arbiter_branch %>
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
