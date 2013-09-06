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
        unless header =  UserDataTemplates[os_type]
          raise Error.new("No user data template for OS of type (#{os_type})")
        end
         header + cloud_init_user_data + "\n"
      end
      UserDataTemplateDefault = <<eos
#!/bin/sh

eos
      UserDataTemplateUbuntu = <<eos
#cloud-boothook
#!/bin/sh 
eos
      UserDataTemplates = {
        :ubuntu => UserDataTemplateUbuntu,
        :redhat => UserDataTemplateDefault,
        :centos => UserDataTemplateDefault,
        :debian => UserDataTemplateDefault
      }
    end
  end
end; end
