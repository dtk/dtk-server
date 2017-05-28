require 'mime'
require 'base64'

module DTKModule
  class Ec2::Node::Operation::Create
    module UserData
      def self.aws_form?(params)
        aws_form__dtk_agent_info?(params)
      end

      private

      DTK_AGENT_ATTRIBUTES = [:install_script, :cloud_config]
      def self.aws_form__dtk_agent_info?(params)
        if dtk_agent_info = params.dtk_agent_info
          user_data_info = { os_type: params.os_type }
          user_data_info = DTK_AGENT_ATTRIBUTES.inject(user_data_info) { |h, k| (val = dtk_agent_info[k]) ? h.merge(k => val) : h }
          missing_attrs = DTK_AGENT_ATTRIBUTES - user_data_info.keys
          fail Error::Usage, "The hash dtk_agent_info is missing attributes: #{missing_attrs.join(' ')}" unless missing_attrs.empty?
          { user_data: Base64.encode64(embed_in_os_specific_wrapper(user_data_info)) }
        end
      end

      private
      # user_data_info has keys:
      #   :install_script
      #   :cloud_config
      #   :os_type
      def self.embed_in_os_specific_wrapper(user_data_info)
        os_type = user_data_info[:os_type]
        header = header(user_data_info[:os_type])

        mime_message = MIME::Multipart::Mixed.new
        mime_message.add(create_mime_message_part("#{header}#{user_data_info[:install_script]}\n", 'x-shellscript', 'script.sh'))
        mime_message.add(create_mime_message_part(user_data_info[:cloud_config], 'cloud-config', 'cloud.cfg'))
        mime_message.to_s
      end

      MIME_MESSAGE_ENCODING = '7bit'
      MIME_VERSION = '1.0'
      def self.create_mime_message_part(message, content_subtype, filename = "plain.txt")
        message_encoding = MIME_MESSAGE_ENCODING
        message_disposition = "attachment; filename=#{filename}"
        mime_version = MIME_VERSION
        message_part = MIME::Text.new(message, content_subtype)

        message_part.mime_version = mime_version
        message_part.transfer_encoding = message_encoding
        message_part.disposition = message_disposition
        message_part
      end

      def self.header(os_type)
        OSTemplates[os_type] || fail(DTK::Error::Usage, "Unsupported OS type (#{os_type}); supported types are: #{SupportedOSList.join(', ')}")
      end

      OSTemplateDefault = <<eos
#!/bin/sh

eos
      OSTemplateUbuntu = <<eos
#!/bin/sh
eos
      OSTemplates = {
        'ubuntu'       => OSTemplateUbuntu,
        'redhat'       => OSTemplateDefault,
        'centos'       => OSTemplateDefault,
        'debian'       => OSTemplateDefault,
        'amazon-linux' => OSTemplateDefault
      }
      SupportedOSList = OSTemplates.keys

    end
  end
end
