module DTK
  module CommandAndControlAdapter
    class Mcollective
      class Config
        require 'tempfile'
        require 'erubis'
        Lock = Mutex.new
        def self.mcollective_client()
          Lock.synchronize do
            @mcollective_client ||= create_mcollective_client()
          end
        end

        def self.ret_cloud_init_user_data(node,bindings)
          create().cloud_init_user_data(node,bindings)
        end

        def cloud_init_user_data(node,bindings)
          all_bindings = cloud_init_user_data_bindings(node,bindings)
          erubis_object(cloud_init_user_data_erb()).result(all_bindings)
        end

       private
        def self.create_mcollective_client()
          config_file_content = mcollective_config_file()
          begin
            #TODO: see if can pass args and not need to use tempfile
            config_file = Tempfile.new("client.cfg")
            config_file.write(config_file_content)
            config_file.close
            ret = ::MCollective::Client.new(config_file.path)
            ret.options = {}
            ret
           ensure
            config_file.unlink
          end
        end

        def self.create()
          type = (R8::Config[:mcollective][:auth_type]||:default).to_sym
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

        def self.mcollective_config_file()
          create().mcollective_config_file()
        end

        def mcollective_config_erubis_object()
          erubis_content = File.open(File.expand_path("auth/#{@type}/client.cfg.erb", File.dirname(__FILE__))).read
          erubis_object(erubis_content)
        end

        def logfile()
          "/var/log/mcollective/#{Common::Aux.running_process_user()}/client.log"
        end

        def erubis_object(erubis_content)
          ::Erubis::Eruby.new(erubis_content)
        end

        class Default < self
          def mcollective_config_file()
            mcollective_config_erubis_object().result(
              :logfile => logfile(),
              :stomp_host => Mcollective.server_host(),
              :mcollective_username => R8::Config[:mcollective][:username],
              :mcollective_password => R8::Config[:mcollective][:password],
              :mcollective_collective => R8::Config[:mcollective][:collective])
          end
         private
          def cloud_init_user_data_erb()
            USER_DATA_SH_ERB
          end
          
          def cloud_init_user_data_bindings(node,bindings)
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
          #TODO: validate the R8::Config[:mcollective][:ssh] params
          def mcollective_config_file()
            mcollective_config_erubis_object().result(
              :logfile => logfile(),
              :stomp_host => Mcollective.server_host(),
              :mcollective_ssh_local_public_key => R8::Config[:mcollective][:ssh][:local][:public_key],
              :mcollective_ssh_local_private_key => R8::Config[:mcollective][:ssh][:local][:private_key],
              :mcollective_ssh_local_authorized_keys => R8::Config[:mcollective][:ssh][:local][:authorized_keys],
              :mcollective_username => R8::Config[:mcollective][:username],
              :mcollective_password => R8::Config[:mcollective][:password],
              :mcollective_collective => R8::Config[:mcollective][:collective]
            )
          end
         private

          def cloud_init_user_data_bindings(node,bindings)
            #TODO: clean up to have error checking
            ssh_remote_public_key=File.open(R8::Config[:mcollective][:ssh][:remote][:public_key], 'rb') { |f| f.read }
            ssh_remote_private_key=File.open(R8::Config[:mcollective][:ssh][:remote][:private_key], 'rb') { |f| f.read }
            ssh_local_public_key=File.open(R8::Config[:mcollective][:ssh][:local][:public_key], 'rb') { |f| f.read }
            #order of merge does not matter; keys wont conflict
            bindings.merge(
              :mcollective_ssh_remote_public_key => ssh_remote_public_key,
              :mcollective_ssh_remote_private_key => ssh_remote_private_key,
              :mcollective_ssh_local_public_key => ssh_local_public_key,
              :mcollective_username => R8::Config[:mcollective][:username],
              :mcollective_password => R8::Config[:mcollective][:password],
              :mcollective_collective => R8::Config[:mcollective][:collective],
              #TODO: will generalize so not just puppet                           
              :puppet_version => node.attribute().puppet_version()||''
            )
          end

          def cloud_init_user_data_erb()
            USER_DATA_SH_ERB
          end

          USER_DATA_SH_ERB = <<eos
cat << EOF >> /etc/mcollective/server.cfg
---
plugin.stomp.host = <%=node_config_server_host %>
main_collective = <%=mcollective_collective %>
collectives = <%=mcollective_collective %>

plugin.stomp.user = <%=mcollective_username %>
plugin.stomp.password = <%=mcollective_password %>
EOF

cat << EOF > /etc/mcollective/facts.yaml
---
git-server: "<%=git_server_url %>"
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

/etc/init.d/mcollective* restart

eos

        end
      end
    end
  end
end

