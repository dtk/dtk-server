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
        cloud_init_user_data = CommandAndControl.cloud_init_user_data(template_bindings)
        embed_in_os_specific_wrapper(os_type.to_sym,cloud_init_user_data)
      end
      private
      def self.embed_in_os_specific_wrapper(os_type,cloud_init_user_data)
        pp [:cloud_init_user_data,cloud_init_user_data]
        raise ErrorUsage.new("got here")
      end
    end
  end
end; end
=begin
      
pp [:foo_debug,CommandAndControl.cloud_init_user_data()]


        mcollective_ssh_remote_public_key=File.open(R8::Config[:mcollective][:ssh][:remote][:public_key], 'rb') { |f| f.read }
        mcollective_ssh_remote_private_key=File.open(R8::Config[:mcollective][:ssh][:remote][:private_key], 'rb') { |f| f.read }
        mcollective_ssh_local_public_key=File.open(R8::Config[:mcollective][:ssh][:local][:public_key], 'rb') { |f| f.read }
        template_bindings = {
          :node_config_server_host => node_config_server_host,
          :git_server_url => git_server_url, 
          :git_server_dns => git_server_dns,
          :fingerprint => fingerprint,
          :mcollective_ssh_remote_public_key => mcollective_ssh_remote_public_key,
          :mcollective_ssh_remote_private_key => mcollective_ssh_remote_private_key,
          :mcollective_ssh_local_public_key => mcollective_ssh_local_public_key
        }
        unbound_bindings = template_bindings.reject{|k,v|v}
        raise Error.new("Unbound cloudint var(s) (#{unbound_bindings.values.join(",")}") unless unbound_bindings.empty?
        UserDataTemplates[os_type.to_sym] && UserDataTemplates[os_type.to_sym].result(template_bindings)
      end
    #TODO: put this as boothook because if not get race condition with start of mcollective
#need to check if this now runs on every boot; if so might want to put provision in so only runs on first boot


UserDataTemplates = Hash.new 
# Ubuntu template
UserDataTemplates[:ubuntu] = Erubis::Eruby.new <<eos
#cloud-boothook
#!/bin/sh 

#{USER_DATA_SH}

eos

# Red Hat template
UserDataTemplates[:redhat] = Erubis::Eruby.new <<eos
#!/bin/sh 

#{USER_DATA_SH}

eos

# CentOS template
UserDataTemplates[:centos] = Erubis::Eruby.new <<eos
#!/bin/sh

#{USER_DATA_SH}

eos


UserDataTemplates[:debian] = Erubis::Eruby.new <<eos
#!/bin/sh 

#{USER_DATA_SH}

eos

    end
  end
end; end
=end
