module DTK
  class CommandAndControl
    class InstallScript
      def self.install_script(node)
        new(node).install_script()
      end
      def initialize(node)
        @node = node
        @os_type = os_type()
      end
      def install_script()
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
        install_script = CommandAndControl.node_config_adapter_install_script(@node,template_bindings)
        embed_in_os_specific_wrapper(install_script)
      end

     private
      def os_type()
        unless os_type = @node.get_field?(:os_type)
          raise Error.new("#{node_name_and_id()} does not have an OS type specified")
        end
        os_type = os_type.to_sym
        unless SupportedOSList.include?(os_type)
          supported_list = SupportedOSList.join(', ')
          raise ErrorUsage.new("#{node_name_and_id()} has an unsupported OS type (#{os_type}); supported types are: #{supported_list}")
        end
        os_type
      end
      def node_name_and_id()
        @node.pp_name_and_id(:capitalize => true)
      end

      def embed_in_os_specific_wrapper(install_script)
        header =  OSTemplates[@os_type]
        header + install_script + "\n"
      end
      OSTemplateDefault = <<eos
#!/bin/sh

eos
      OSTemplateUbuntu = <<eos
#!/bin/sh 
eos
      OSTemplates = {
        :ubuntu               => OSTemplateUbuntu,
        :redhat               => OSTemplateDefault,
        :centos               => OSTemplateDefault,
        :debian               => OSTemplateDefault,
        'amazon-linux'.to_sym => OSTemplateDefault,
      }
      SupportedOSList = OSTemplates.keys
    end
  end
end

