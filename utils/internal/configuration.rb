#TODO: this is in midst of converting from old form to new form
require 'singleton'
module DTK
  class Configuration
    include Singleton
    def set_configuration(config_file_location=nil)
      config_file_location ||= default_config_file_location() 
      set_defaults()
      load_config_file(config_file_location)
      set_combined_vars()
      validate()
      finalize()
    end

    private
    def default_config_file_location()
      username = ENV["USER"]||ENV["USERNAME"]
      user_specific_config = "#{BaseConfigDir}/#{username}/server.conf"
      File.file?(user_specific_config) ? user_specific_config : "#{BaseConfigDir}/server.conf"
    end
    BaseConfigDir = "/etc/dtk"

    def set_defaults()
      #TODO: to modify
      r8_nested_require('configuration','defaults')
    end
    
    def set_combined_vars()
      r8_nested_require('configuration','combined')
    end

    def load_config_file(config_file_location)
      parsed_file = ParsedFile.new(config_file_location)
      parsed_file.each do |key,value|
        update_config_value!(key,value)
      end
    end

    def update_config_value!(config_file_key,value)
      internal_key = (Mappings[config_file_key]||config_file_key).split(".")
      update_config_value_aux!(R8::Config,internal_key,value)
    end

    Mappings = {
      "remote_repo.host" => "repo.remote.host",
      "local_repo.host" => "repo.git.dns",
      "db.host" => "database.hostname",
      "mcollective.host" => "command_and_control.node_config.mcollective.host"
    }

    def update_config_value_aux!(base,internal_key,value)
      index = internal_key.first.to_sym
      if internal_key.size == 1
        base[index] = value
      else
        update_config_value_aux!(base[index],internal_key[1,internal_key.size-1],value)
      end
    end

    RequiredNonDefaultKeys = Mappings.values #TODO: stub setting
    def validate
      #TODO: need to check for legal values
      #STUB use RequiredNonDefaultKeys
    end
    def finalize()
      #freeze
      R8::Config.recursive_freeze
    end

    class ParsedFile < Hash
      def initialize(file)
        super()
        replace(parse_key_value_file(file))
      end
      def parse_key_value_file(file)
        ret = Hash.new
        raise ErrorUsage.new("Config file (#{file}) does not exists") unless File.exists?(file)
        File.open(file).each do |line|
          # strip blank spaces, tabs etc off the end of all lines
          line.gsub!(/\s*$/, "")
          unless line =~ /^#|^$/
            if (line =~ /(.+?)\s*=\s*(.+)/)
              key = $1
              val = $2
              ret[key] = val
            end
          end
        end
        ret
      end
    end
  end
end
