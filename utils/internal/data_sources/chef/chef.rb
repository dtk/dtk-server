require 'chef/rest'
require 'chef/config'
require 'mixlib/authentication'

module XYZ
  module DSAdapter
    class Chef
      class Top < DataSourceAdapter
        class << self
          def get_list__component()
             # get_rest("cookbooks")
            %w{pg_pool postgresql} #stub
          end
          def get_objects__component(name)
            r = get_rest("cookbooks/#{cookbook_name}")
            ret = Array.new
            return ret if r.nil?
            metadata = r["metadata"]
            return ret if metadata.nil?
            if r["recipes"]
               r["recipes"].each do |recipe_name,description|
                 ret << {"metadata" => metadata, "name" => recipe_name, "description" => description}
               end
            else
              ret << {"metadata" => metadata, "name" => metadata["name"], "description" => metadata["description"]}
            end
            ret
          end

          def get(object_path)
            if object_path =~ %r{^/cookbooks$}
              # get_rest("cookbooks")
              %w{pg_pool postgresql} #stub
            elsif object_path =~ %r{^/cookbooks/([A-Z0-9a-z_-]+)/metadata$}
              cookbook_name = $1
              r = get_rest("cookbooks/#{cookbook_name}")
              r ? r["metadata"] : nil
            end
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

