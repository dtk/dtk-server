require File.expand_path("data_source_adapter", File.dirname(__FILE__))
require 'chef/rest'
require 'chef/config'
require 'mixlib/authentication'

module XYZ
  module DSAdapter
    class Chef
      class Top < DataSourceAdapter
        class << self
          def get_rest(item)
            rest_results = connection().get_rest(item)
            rest_results ? rest_results.to_hash : nil
          end
         private
          def connection()
            @@connection ||=  initialize_chef_connection()
          end
          def initialize_chef_connection()
            ::Chef::Config.from_file("/root/.chef/knife.rb") #TBD: stub; will replace by passing in relavant paramters
            ::Chef::Log.level(::Chef::Config[:log_level])
            ::Mixlib::Authentication::Log.logger = ::Chef::Log.logger
            ::Chef::REST.new(::Chef::Config[:chef_server_url], ::Chef::Config[:node_name],::Chef::Config[:client_key])
          end
        end
      end
    end
  end
end

