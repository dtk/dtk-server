#TODO: user common utils in DTK::Common::Rest
require 'rubygems'
require 'singleton'
require 'restclient'
require 'json'
require 'pp'
#TODO: for testing; fix by pass in commadn line argument
#RestClient.log = STDOUT

def top_level_execute(command=nil)
  $: << "/usr/lib/ruby/1.8/" #TODO: put in to get around path problem in rvm 1.9.2 environment
  include DTK::Client
  include Aux
  command = command || $0.gsub(Regexp.new("^.+/"),"").gsub("-","_")
  load_command(command)
  
  conn = Conn.new()

  command_class = DTK::Client.const_get "#{cap_form(command)}Command"
  response_ruby_obj = command_class.execute_from_cli(conn,ARGV)
  #default_render_type = "hash_pretty_print"
  default_render_type = "augmented_simple_list" #TODO: doe not work for nested hashes
  if print = response_ruby_obj.render_data(default_render_type)
    print = [print] unless print.kind_of?(Array)
    print.each do |el|
      if el.kind_of?(String)
        el.each_line{|l| STDOUT << l}
      else
        PP.pp(el,STDOUT)
      end
    end
  end
end

module DTK
  module Client
    class Error < NameError
    end

    class Log
      #TODO Stubs
      def self.info(msg)
        pp "info: #{msg}"
      end
      def self.error(msg)
        pp "error: #{msg}"
      end
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
      ConfigFile = "/etc/dtk/client.conf"
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

    class Response < Common::Rest::Response
      def initialize(command_class=nil,hash={})
        super(hash)
        @command_class = command_class
      end

      def render_data(view_type)
        if ok?()
          ViewProcessor.render(@command_class,data,view_type)
        else
          hash_part()
        end
      end
     private
      def hash_part()
        keys.inject(Hash.new){|h,k|h.merge(k => self[k])}
      end
    end

    class ResponseError < Response
      include Common::Rest::ResponseErrorMixin
      def initialize(hash={})
        super(nil,hash)
      end
    end

    class ResponseBadParams < ResponseError
      def initialize(bad_params_hash)
        errors = bad_params_hash.map do |k,v|
          {"code"=>"bad_parameter","message"=>"Parameter (#{k}) has a bad value: #{v}"}
        end
        hash = {"errors"=>errors, "status"=>"notok"}
        super(hash)
      end
    end

    class ResponseNoOp < Response
      def render_data(view_type)
      end
    end

    class Conn
      def initialize()
        @cookies = Hash.new
        @connection_error = nil
        login()
      end
      attr_reader :connection_error

      #######
      def rest_url(route)
        "http://#{Config[:server_host]}:#{Config[:server_port].to_s}/rest/#{route}"
      end

      def get(command_class,url)
        Response.new(command_class,json_parse_if_needed(get_raw(url)))
      end

      def post(command_class,url,body=nil)
        Response.new(command_class,json_parse_if_needed(post_raw(url,body)))
      end

      private
      include ParseFile
      def login()
        creds = get_credentials()
        response = post_raw rest_url("user/process_login"),creds
        if response.kind_of?(Common::Rest::Response) and not response.ok?
          @connection_error = response
        else
          @cookies = response.cookies
        end
      end
      def get_credentials()
        cred_file = File.expand_path("~/.dtkclient")
        raise Error.new("Credential file (#{cred_file}) does not exist") unless File.exists?(cred_file)
        ret = parse_key_value_file(cred_file)
        [:username,:password].each{|k|raise Error.new("cannot find #{k}") unless ret[k]}
        ret
      end

      ####
      DefaultRestOpts = {:timeout => 20, :open_timeout => 0.5, :error_response_class => Client::ResponseError}
      def get_raw(url)
        Common::Rest::ClientWrapper.get_raw(url,DefaultRestOpts.merge(:cookies => @cookies))
      end
      def post_raw(url,body)
        Common::Rest::ClientWrapper.post_raw(url,body,DefaultRestOpts.merge(:cookies => @cookies))
      end

      def json_parse_if_needed(item)
        Common::Rest::ClientWrapper.json_parse_if_needed(item)
      end
    end
  end
end
