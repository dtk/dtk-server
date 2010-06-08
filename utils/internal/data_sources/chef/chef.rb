require 'chef/rest'
require 'chef/config'
require 'mixlib/authentication'

module XYZ
  module DSAdapter
    class Chef
      class Top < DataSourceAdapter

        def get_objects__component(&block)
          get_cookbook_names().each do |cookbook_name|
            get_recipes_assoc_cookbook(cookbook_name).each do |ds_attr_hash|
              block.call(ds_attr_hash)
            end
          end
        end

       private
        def get_cookbook_names()
          # get_rest("cookbooks")
          %w{pg_pool postgresql} #stub
        end

        def get_recipes_assoc_cookbook(cookbook_name)
          r = get_rest("cookbooks/#{cookbook_name}")
          ret = Array.new
          return ret if r.nil?

          metadata = r["metadata"]
          return ret if metadata.nil?

          if metadata["recipes"]
             metadata["recipes"].each do |recipe_name,description|
               ret << {"metadata" => metadata, "name" => recipe_name, "description" => description}
             end
          else
            ret << {"metadata" => metadata, "name" => metadata["name"], "description" => metadata["description"]}
          end
          ret
        end

        def get_rest(item)
          rest_results = conn().get_rest(item)
          rest_results ? rest_results.to_hash : nil
        end

        def conn()
          @@conn ||=  initialize_chef_connection()
        end

        def initialize_chef_connection()
          ::Chef::Config.from_file("/root/.chef/knife.rb") #TBD: stub; will replace by passing in relavant paramters
          ::Chef::Log.level(::Chef::Config[:log_level])
#What is mixlib?
          ::Mixlib::Authentication::Log.logger = ::Chef::Log.logger
          ::Chef::REST.new(::Chef::Config[:chef_server_url], ::Chef::Config[:node_name],::Chef::Config[:client_key])
        end
      end
    end
  end
end


