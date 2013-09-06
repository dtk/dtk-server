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

        def self.mcollective_config_file()
          create().mcollective_config_file()
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


        def erubis_object()
          erubis_content = File.open(File.expand_path("mcollective/auth/#{@type}/client.cfg.erb", File.dirname(__FILE__))).read
          ::Erubis::Eruby.new(erubis_content)
        end

        def logfile()
          "/var/log/mcollective/#{Common::Aux.running_process_user()}/client.log"
        end

        class Default < self
          def mcollective_config_file()
            erubis_object().result(:logfile => logfile(),:stomp_host => Mcollective.server_host())
          end
        end

        class Ssh < self
          #TODO: validate the R8::Config[:mcollective][:ssh] params
          def mcollective_config_file()
            erubis_object().result(
              :logfile => logfile(),
              :stomp_host => Mcollective.server_host(),
              :mcollective_ssh_local_public_key => R8::Config[:mcollective][:ssh][:local][:public_key],
              :mcollective_ssh_local_private_key => R8::Config[:mcollective][:ssh][:local][:private_key],
              :mcollective_ssh_local_authorized_keys => R8::Config[:mcollective][:ssh][:local][:authorized_keys]
            )
          end
        end
      end
    end
  end
end

