require 'chef/rest'
require 'chef/config'
require 'mixlib/authentication'

module XYZ
  module DSAdapter
    class Chef
      class Top < DataSourceAdapter
        class << self
#TODO: Whats the diff between get_objects and get_list?
#TODO: Is there a design benefit to have the get list component a this level and not in the 
#      specific adapter file?

          def get_list__component()
             # get_rest("cookbooks")
            %w{pg_pool postgresql} #stub
          end

          def get_objects__component(cookbook_name)
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

         private

          def get_rest(item)
            rest_results = conn().get_rest(item)
            rest_results ? rest_results.to_hash : nil
          end
#TODO: There is quite the mix of really short/abreviated names, and really verbose/descriptive ones
#TODO: What are the dependencies of the chef files that are being used to communicate to teh server?
#      Want to be mindful of this running on windows
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
end

