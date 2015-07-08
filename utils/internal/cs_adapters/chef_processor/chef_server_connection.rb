
require 'chef/rest'
require 'mixlib/authentication'
module XYZ
  class ChefProcessor
    # instance mixin
    module ChefServerConnection
      def initialize_chef_connection(_chef_server_uri) #TBD: chef_server_uri is stub
        Chef::Config.from_file("/etc/chef/client.rb") #TBD: stub; will replace by passing in relavant paramters
        Chef::Log.level(ENV.key?("LOG_LEVEL") ? ENV["LOG_LEVEL"].to_sym : Chef::Config[:log_level])
        Mixlib::Authentication::Log.logger = Chef::Log.logger

        Chef::Config[:node_name] = "chef-webui" #TDB: stub until pass in auth
        Chef::Config[:client_key] = "/etc/chef/webui.pem"
        @rest = Chef::REST.new(Chef::Config[:chef_server_url], Chef::Config[:node_name],Chef::Config[:client_key])
      end

      def get_rest(item)
        @rest.get_rest(item)
      end
    end
  end
end
