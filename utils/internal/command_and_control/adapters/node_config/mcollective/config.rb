module DTK
  module CommandAndControlAdapter
    class Mcollective
      class Config
        require 'tempfile'
        require 'erubis'
        Lock = Mutex.new

        def self.mcollective_client
          Lock.synchronize do
            @mcollective_client ||= create_mcollective_client()
          end
        end

        def self.install_script(node, bindings)
          create().install_script(node, bindings)
        end

        def install_script(node, bindings)
          all_bindings = install_script_bindings(node, bindings)
          erubis_object(install_script_erb()).result(all_bindings)
        end

        def self.discover(filter, timeout, limit, client)
          ::MCollective::Discovery::Mc.discover(filter, timeout, limit, client)
        end

        private

        def self.create_mcollective_client
          config_file_content = mcollective_config_file()
          begin
            # TODO: see if can pass args and not need to use tempfile
            config_file = Tempfile.new('client.cfg')
            config_file.write(config_file_content)
            config_file.close
            ret = ::MCollective::Client.new(config_file.path)
            ret.options = {}
            ret
           ensure
            config_file.unlink
          end
        end

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

        def self.mcollective_config_file
          create().mcollective_config_file()
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
          def mcollective_config_file
            mcollective_config_erubis_object().result(
              logfile: logfile(),
              stomp_host: Mcollective.server_host(),
              stomp_port: Mcollective.server_port(),
              mcollective_username: R8::Config[:mcollective][:username],
              mcollective_password: R8::Config[:mcollective][:password],
              mcollective_collective: R8::Config[:mcollective][:collective])
          end

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
          # TODO: validate the R8::Config[:mcollective][:ssh] params
          def mcollective_config_file
            mcollective_config_erubis_object().result(
              logfile: logfile(),
              stomp_host: Mcollective.server_host(),
              stomp_port: Mcollective.server_port(),
              mcollective_ssh_local_public_key: R8::Config[:mcollective][:ssh][:local][:public_key],
              mcollective_ssh_local_private_key: R8::Config[:mcollective][:ssh][:local][:private_key],
              mcollective_ssh_local_authorized_keys: R8::Config[:mcollective][:ssh][:local][:authorized_keys],
              mcollective_username: R8::Config[:mcollective][:username],
              mcollective_password: R8::Config[:mcollective][:password],
              mcollective_collective: R8::Config[:mcollective][:collective]
            )
          end

          private

          def install_script_bindings(node, bindings)
            # TODO: clean up to have error checking
            ssh_remote_public_key = File.open(R8::Config[:mcollective][:ssh][:remote][:public_key], 'rb') { |f| f.read }
            ssh_remote_private_key = File.open(R8::Config[:mcollective][:ssh][:remote][:private_key], 'rb') { |f| f.read }
            ssh_local_public_key = File.open(R8::Config[:mcollective][:ssh][:local][:public_key], 'rb') { |f| f.read }
            pbuilderid = (node.pbuilderid() if node.get_iaas_type() == :physical)
            # order of merge does not matter; keys wont conflict
            bindings.merge(
              mcollective_ssh_remote_public_key: ssh_remote_public_key,
              mcollective_ssh_remote_private_key: ssh_remote_private_key,
              mcollective_ssh_local_public_key: ssh_local_public_key,
              mcollective_username: R8::Config[:mcollective][:username],
              mcollective_password: R8::Config[:mcollective][:password],
              mcollective_collective: R8::Config[:mcollective][:collective],
              mcollective_restart: mcollective_restart(node),
              stomp_port: Mcollective.server_port(),
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
              dtk_arbiter_update: R8::Config[:dtk_arbiter][:update]
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
cat << EOF >> /etc/mcollective/server.cfg
---
plugin.stomp.host = <%=node_config_server_host %>
plugin.stomp.port = <%=stomp_port %>
main_collective = <%=mcollective_collective %>
collectives = <%=mcollective_collective %>

plugin.stomp.user = <%=mcollective_username %>
plugin.stomp.password = <%=mcollective_password %>
EOF

cat << EOF > /etc/mcollective/facts.yaml
---
git-server: "<%=git_server_url %>"
<% if pbuilderid %>
pbuilderid: <%= pbuilderid %>
<% end %>
EOF

mkdir -p /etc/mcollective/ssh

cat << EOF > /etc/mcollective/ssh/mcollective
<%=mcollective_ssh_remote_private_key %>
EOF

cat << EOF > /etc/mcollective/ssh/mcollective.pub
<%=mcollective_ssh_remote_public_key %>
EOF

cat << EOF > /etc/mcollective/ssh/authorized_keys
<%=mcollective_ssh_local_public_key %>
EOF

ssh-keygen -f "/root/.ssh/known_hosts" -R <%=git_server_dns %>
cat << EOF >>/root/.ssh/known_hosts
<%=fingerprint %>
EOF

<% unless puppet_version.empty? %>
/opt/puppet-omnibus/embedded/bin/gem uninstall -aIx puppet
/opt/puppet-omnibus/embedded/bin/gem install puppet -v <%= puppet_version %> --no-rdoc --no-ri
<% end %>

<% if dtk_arbiter_update %>
[ -x /usr/share/dtk/dtk-arbiter/update.sh ] && /usr/share/dtk/dtk-arbiter/update.sh
<% end %>

<% if mcollective_restart %>
/etc/init.d/mcollective* restart
[ -x /etc/init.d/dtk-arbiter ] && /etc/init.d/dtk-arbiter restart
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
