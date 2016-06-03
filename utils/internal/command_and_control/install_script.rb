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
require 'mime'

module DTK
  class CommandAndControl
    class InstallScript
      # opts can have keys:
      #  :os_type
      def self.install_script(node, opts = {})
        new(node, opts).install_script
      end
      def initialize(node, opts = {})
        @node = node
        @os_type = (opts[:os_type] || os_type).to_sym
      end

      def install_script
        git_server_url = RepoManager.repo_url()
        git_server_dns = RepoManager.repo_server_dns()
        node_config_server_host = CommandAndControl.node_config_server_host()
        fingerprint = RepoManager.repo_server_ssh_rsa_fingerprint()
        template_bindings = {
          node_config_server_host: node_config_server_host,
          git_server_url: git_server_url,
          git_server_dns: git_server_dns,
          fingerprint: fingerprint
        }
        install_script = CommandAndControl.node_config_adapter_install_script(@node, template_bindings)
        cloud_config_options = CommandAndControl.node_config_adapter_cloud_config_options(@node, template_bindings)
        cloud_config_os_type = CommandAndControl.node_config_adapter_cloud_config_os_type
        embed_in_os_specific_wrapper(install_script, cloud_config_options, cloud_config_os_type)
      end

      private
      require 'mime'
      include MIME
      def create_mime_shell_message(script)
        content_subtype = 'x-shellscript'
        msg_part = MIME::Text.new(script, content_subtype)
        msg_part.transfer_encoding = '7bit'
        msg_part.disposition = 'attachment'
        msg_part
      end

      def create_mime_cloud_config_messag(cloud_config_options)
        content_subtype = 'cloud-config'
        msg_part = MIME::Text.new(cloud_config_options, content_subtype)
        msg_part.transfer_encoding = '7bit'
        msg_part.disposition = 'attachment'
        msg_part
      end

      def embed_in_os_specific_wrapper(install_script, cloud_config_options, cloud_config_os_type)
        mime_message = MIME::Multipart::Mixed.new

        raise_error_unsupported_os(@os_type) unless header =  OSTemplates[@os_type]
        
        mime_message.add(create_mime_shell_message(header + install_script + "\n"))
        mime_message.add(create_mime_cloud_config_messag(cloud_config_options)) if cloud_config_os_type.include? @os_type
        mime_message.to_s
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
        'amazon-linux'.to_sym => OSTemplateDefault
      }
      SupportedOSList = OSTemplates.keys

      def raise_error_unsupported_os(os_type)
          supported_list = SupportedOSList.join(', ')
          fail ErrorUsage.new("#{node_name_and_id()} has an unsupported OS type (#{os_type}); supported types are: #{supported_list}")
      end

      def node_name_and_id
        @node.pp_name_and_id(capitalize: true)
      end

      # TODO:: DTK-2489: deprecate
      def os_type
        unless os_type = @node.get_field?(:os_type)
          fail Error.new("#{node_name_and_id()} does not have an OS type specified")
        end
        os_type = os_type.to_sym
        unless SupportedOSList.include?(os_type)
          raise_error_unsupported_os(os_type)
        end
        os_type
      end

    end
  end
end
