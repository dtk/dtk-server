#!/usr/bin/env ruby

this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir, 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'grpc'
require_relative 'lib/json/lib/json'
require 'dtkarbiterservice_services_pb'
require_relative 'lib/open3.rb'
require_relative 'lib/dtk'

class ArbiterGRPCServer < Dtkarbiterservice::ArbiterProvider::Service

  include Arbiter::Common::Open3
  
  RUBY_BINARY      = '/usr/bin/ruby'
  GEM_BINARY       = '/usr/bin/gem'
  MODULE_PATH      = '/usr/share/dtk/modules'
  PROVIDER_MODULE_PATH = '/usr/share/dtk/modules/dtk-provider-ruby'
  DEFAULT_RUBY_VERSION     = '2.3.3'

  def process(provider_message, _unused_call)
  begin
    response = {}
    provider_message_hash = JSON.parse(provider_message.message)
    #gem_list = provider_message_hash['provider']['gems']
    ruby_version = provider_message_hash['provider']['ruby_version'] || DEFAULT_RUBY_VERSION
    entrypoint = provider_message_hash['provider']['entrypoint']
    component_name = provider_message_hash['component_name']
    module_name = provider_message_hash['module_name']
    dtk_debug = provider_message_hash['dtk_debug']
    dtk_debug_port = provider_message_hash['dtk_debug_port']
    module_path_absolute = "#{MODULE_PATH}/#{module_name}"
    entrypoint_absolute = "#{module_path_absolute}/#{entrypoint}" 
    instance_attributes = generate_attributes(provider_message_hash)
    #@entrypoint = '/usr/share/dtk/modules/rubytest/bin/run.rb'
  rescue Exception => e
    response[:error] = 'true'
    response[:error_message] = e.message
    response[:stack_trace] = e.backtrace.inspect
    return Dtkarbiterservice::ArbiterMessage.new(message: response.to_json)
  end    

    # if custom ruby version of gem list sent
    # assume it needs to be executed in docker
#    if gem_list || ruby_version
#      dockerfile = generate_dockerfile(provider_message_hash)
      #response[:execution_type] = 'ephemeral'
#      response[:dockerfile] = dockerfile
#    else 
      #install_gems(gem_list)
#      output = run()
#      response[:stdout] = output
#    end

    # call the provider entrypoint
    # and pass the attributes
    begin
      # in case that dtk_debug is set to true
      # start the remote debugger on the specified (or default) port
      # the execution will halt, waiting for the remote debugger to start
      # dtk-arbiter is supposed to be aware of the debug flag
      if dtk_debug
        start_debugger(dtk_debug_port)
      end
      load entrypoint_absolute
      execution_response = ::DTKModule.execute(instance_attributes)
      response.merge!(execution_response)
    rescue Exception, LoadError => e
      response[:error] = 'true'
      response[:error_message] = e.message
      response[:stack_trace] = e.backtrace.inspect
    end

    #@provider_message_hash = JSON.parse(provider_message)
    #Dtkarbiterservice::ArbiterMessage.new(message: "#{provider_message.message}")
    Dtkarbiterservice::ArbiterMessage.new(message: response.to_json)
  end

  def start_debugger(port=8989, wait_connection = true)
    require 'byebug'
    require 'byebug/core'
    Byebug.wait_connection = wait_connection
    Byebug.start_server(get_bind_ip, port)
    debugger
  end

# used for testing purposes
  def install_gems(gem_list)
    gem_list.each do |g|
      system "#{GEM_BINARY} install #{g["name"]} -v #{g["version"]}"
    end
  end

  def generate_dockerfile(message)
    message = message.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    #message[:entrypoint] = "#{MODULE_PATH}/#{message[:module_name]}/#{message[:entrypoint]}"
    message[:entrypoint] = "#{PROVIDER_MODULE_PATH}/init"
    message[:provider_module_path] = PROVIDER_MODULE_PATH
    message[:docker_image_base] = "ruby:#{DEFAULT_RUBY_VERSION}"
    dockerfile_mustache = File.read(File.expand_path('Dockerfile.mustache', File.dirname(__FILE__)))
#    Mustache.render(dockerfile_mustache, message)
  end

 def recursive_symbolize_keys(h)
  case h
   when Hash
      Hash[
        h.map do |k, v|
          [ k.respond_to?(:to_sym) ? k.to_sym : k, recursive_symbolize_keys(v) ]
        end
      ]
    when Enumerable
      h.map { |v| recursive_symbolize_keys(v) }
    else
      h
    end
  end

  def generate_attributes(provider_message_hash)
    instance_attributes = provider_message_hash['instance']
    function_parameters = provider_message_hash['function_parameters']
    # merge function_parameters
    # and overwrite any existing ones in instance_attributes if they exist
    instance_attributes.merge!(function_parameters) if function_parameters
    recursive_symbolize_keys(instance_attributes)
  end

  def run()
    output = `#{@entrypoint}`
    output
  end
end
options = {}
# write pid
File.open(options[:pid] || '/tmp/dtk-provider-ruby.pid', 'w') { |f| f.puts(Process.pid) }

# if running inside a docker container bind to 0.0.0.0
# otherwise bind to localhost
def get_bind_ip
  File.exist?('/.dockerenv') ? '0.0.0.0' : '127.0.0.1'
end
 
puts 'Starting dtk-ruby-provider gRPC server...'
# main starts an RpcServer that receives requests to GreeterServer at the sample
# server port.
def main(port)
  s = GRPC::RpcServer.new
  s.add_http2_port("#{get_bind_ip}:#{port}", :this_port_is_insecure)
  s.handle(ArbiterGRPCServer)
  s.run
end

port = ARGV[0] || '50051'

main(port)


