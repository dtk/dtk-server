require File.expand_path("data_source_adapter", File.dirname(__FILE__))
require 'chef/rest'
require 'chef/config'
require 'mixlib/authentication'

module XYZ
  module DSAdapter
    class Chef
      class Top < DataSourceAdapter
        class << self
         def get_cookbook_list()
           get_rest("cookbooks")
         end
         def get_cookbook_metadata(cookbook_name)
           r = get_rest("cookbooks/#{cookbook_name}")
           return nil if r.nil?
           r["metadata"]
         end

         private
          def get_rest(item)
            rest_results = connection().get_rest(item)
            rest_results ? rest_results.to_hash : nil
          end
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

