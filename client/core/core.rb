require 'rubygems'
require 'singleton'
require 'restclient'
require 'json'
require 'pp'

module R8
  class Client
    class Error < NameError
    end

    module ParseFile
      def parse_key_value_file(file)
        #adapted from mcollective config
        ret = Hash.new
        raise Error.new("Config file (#{file}) does not exists") unless File.exists?(file)
        File.open(file).each do |line|
          # strip blank spaces, tabs etc off the end of all lines
          line.gsub!(/\s*$/, "")
          unless line =~ /^#|^$/
            if (line =~ /(.+?)\s*=\s*(.+)/)
              key = $1
              val = $2
              ret[key.to_sym] = val
            end
          end
        end
        ret
      end
    end
    class Config < Hash
      include Singleton
      include ParseFile
      def self.[](k)
        Config.instance[k]
      end
     private
      def initialize()
        set_defaults()
        load_config_file()
        validate()
      end
      def set_defaults()
        self[:server_port] = 7000
      end
      ConfigFile = "/etc/r8client/client.conf"
      def load_config_file()
        parse_key_value_file(ConfigFile).each{|k,v|self[k]=v}
      end
      RequiredKeys = [:server_host]
      def validate
        #TODO: need to check for legal values
        missing_keys = RequiredKeys - keys
        raise Error.new("Missing config keys (#{missing_keys.join(",")})") unless missing_keys.empty?
      end
    end

    class CommandBase
      def initialize(conn)
        @conn = conn
      end

      def get(url)
        @conn.get(url)
      end

      def rest_url(route)
        @conn.rest_url(route)
      end
    end

    class Conn
      def initialize()
        @cookies = Hash.new
        login()
      end

      ####
      def task()
        TaskCommand.new(self)
      end

      #######

      def rest_url(route)
        "http://#{Config[:server_host]}:#{Config[:server_port].to_s}/rest/#{route}"
      end

      def get(url)
        JSON.parse(get_raw(url))
      end


      private
      include ParseFile
      def login()
        creds = get_credentials()
        response = post rest_url("/user/process_login"),creds
        @cookies = response.cookies
      end

      def post(url,body)
        RestClient.post(url,body,:cookies => @cookies)
      end

      def get_raw(url)
        RestClient.get(url,:cookies => @cookies)
      end

      def get_credentials()
        cred_file = File.expand_path("~/.r8client")
        raise Error.new("Credential file (#{cred_file}) does not exist") unless File.exists?(cred_file)
        ret = parse_key_value_file(cred_file)
        [:username,:password].each{|k|raise Error.new("cannot find #{k}") unless ret[k]}
        ret
      end
    end
  end
end
