module DTK; module CommandAndControlAdapter  
  class Ec2
    class CloudInit
      def self.user_data(os_type)
        git_server_url = RepoManager.repo_url()
        git_server_dns = RepoManager.repo_server_dns()
        node_config_server_host = CommandAndControl.node_config_server_host()
        fingerprint = RepoManager.repo_server_ssh_rsa_fingerprint()
        template_bindings = {
          :node_config_server_host => node_config_server_host,
          :git_server_url => git_server_url, 
          :git_server_dns => git_server_dns,
          :fingerprint => fingerprint
        }
        unbound_bindings = template_bindings.reject{|k,v|v}
        raise Error.new("Unbound cloudint var(s) (#{unbound_bindings.values.join(",")}") unless unbound_bindings.empty?
        UserDataTemplates[os_type.to_sym] && UserDataTemplates[os_type.to_sym].result(template_bindings)
      end
    #TODO: put this as boothook because if not get race condition with start of mcollective
#need to check if this now runs on every boot; if so might want to put provision in so only runs on first boot
UserDataTemplates = Hash.new 
UserDataTemplates[:ubuntu] = Erubis::Eruby.new <<eos
#cloud-boothook
#!/bin/sh 

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
UserDataTemplates[:redhat] = Erubis::Eruby.new <<eos
#!/bin/sh 

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

UserDataTemplates[:debian] = Erubis::Eruby.new <<eos
#!/bin/sh 

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
  end
end; end
