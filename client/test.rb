require 'rubygems'
require 'singleton'
require 'restclient'
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
      def initialize()
        load_config_file()
      end
     private
      ConfigFile = "/etc/r8client/client.conf"
      RequiredKeys = [:server_host]
      def load_config_file()
        #TODO: need to check for legal values
        parse_key_value_file(ConfigFile).each{|k,v|self[k]=v}
        missing_keys = RequiredKeys - keys
        raise Error.new("Missinng config keys (#{missing_keys.join(",")})") unless missing_keys.empty?
      end
    end
    def initialize()
      login()
      @cookies = Hash.new
    end
    private
    include ParseFile
    def login()
      creds = get_credentials()
      pp creds
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

R8::Client.new

=begin
r = RestClient.post 'http://localhost:7000/xyz/user/process_login',{"username"=> "joe","password" => "r8server"}
pp r.cookies

pp RestClient.get 'http://localhost:7000/xyz/task/state_info.json', {:cookies =>
{"innate.sid"=>
  "aeba7aa8e632d0c878745638a3506351f9465b025bd1b5429bf6fa341d0d15c2a0c442f26fd092086d53e4b2ca570b041e91a43c900324fa007a8ee9d269f190"}
}
=end
