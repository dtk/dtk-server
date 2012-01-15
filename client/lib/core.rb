require 'rubygems'
require 'singleton'
require 'restclient'
require 'json'
require 'pp'

module R8
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

    module ResponseTokens
      StatusOK = "ok"
      StatusNotok = "notok"
      DataField = "data"
      StatusField = "status"
      ErrorsField = "errors"
      ErrorsSubFieldCode = "code"
      GenericError = "error"
      def error_response(error_or_errors)
        errors = error_or_errors.kind_of?(Hash) ? [error_or_errors] : error_or_errors
        Response.new(StatusField => StatusNotok, ErrorsField => errors)
      end
    end

    class RestClientWrapper 
      class << self
        include ResponseTokens
        def get(url,opts={})
          error_handling do
            ::RestClient.get(url,opts)
          end
        end
        def post(url,body={},opts={})
          error_handling do
            ::RestClient.post(url,body,opts)
          end
        end

        private
        def error_handling(&block)
          begin
            block.call 
          rescue ::RestClient::InternalServerError,::RestClient::RequestTimeout,Errno::ECONNREFUSED => e
            error_response(ErrorsSubFieldCode => RestClientErrors[e.class.to_s]||GenericError)
          rescue Exception => e
            Log.info("Uninterpred error object (#{e.class.to_s})")
            error_response(ErrorsSubFieldCode => GenericError)
          end
        end 
        RestClientErrors = {
          "RestClient::InternalServerError" => "internal_server_error",
          "RestClient::RequestTimeout" => "timeout",
          "Errno::ECONNREFUSED" => "connection_refused"
        }
      end
    end

    class Response < Hash
      include ResponseTokens
      def initialize(hash={})
        super()
        replace(hash)
      end
      def ok?()
        self[StatusField] == StatusOK
      end

      def data()
        self[DataField]
      end

      def render_data(view_type)
        if ok?()
          ViewProcessor.render(data,view_type)
        else
          self
        end
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

      #### command (types)
      def task()
        TaskCommand.new(self)
      end

      #######
      def rest_url(route)
        "http://#{Config[:server_host]}:#{Config[:server_port].to_s}/rest/#{route}"
      end

      def get(url)
        Response.new(json_parse_if_needed(get_raw(url)))
      end

      def post(url,body=nil)
        Response.new(json_parse_if_needed(post_raw(url,body)))
      end

      private
      include ParseFile
      def login()
        creds = get_credentials()
        response = post_raw rest_url("user/process_login"),creds
        if response.kind_of?(Response) and not response.ok?
          @connection_error = response
        else
          @cookies = response.cookies
        end
      end
      def get_credentials()
        cred_file = File.expand_path("~/.r8client")
        raise Error.new("Credential file (#{cred_file}) does not exist") unless File.exists?(cred_file)
        ret = parse_key_value_file(cred_file)
        [:username,:password].each{|k|raise Error.new("cannot find #{k}") unless ret[k]}
        ret
      end

      ####
      def get_raw(url)
        RestClientWrapper.get(url,:cookies => @cookies)
      end
      def post_raw(url,body)
        RestClientWrapper.post(url,body,:cookies => @cookies)
      end

      def json_parse_if_needed(item)
        item.kind_of?(String) ? JSON.parse(item) : item
      end
    end
  end
end
