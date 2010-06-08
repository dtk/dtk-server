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

        def get_objects__assoc_node_component(&block)
          get_node_recipe_assocs().each do |node_name,recipes|
            recipes.each do |recipe|
              ds_attr_hash = {"node_name" => node_name, "recipe_name" => recipe}
              block.call(ds_attr_hash)
            end
          end
        end

       private
        def get_cookbook_names()
          # get_rest("cookbooks")
          #%w{pg_pool postgresql} 
          #stub that just gets cookbooks from run list; it actually has recipes so can pass this in too
          get_node_recipe_assocs().values.flatten.map{|x|x.gsub(/::.+$/,"")}.uniq
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

        def get_node_recipe_assocs()
          recipes = Hash.new
          (get_search_results("node?q=*:*",false)||[]).map do |node|
            recipes[node.name] = node.run_list.recipes
          end
          recipes
        end

        def get_node_recipes(node_name)
          node = get_rest("nodes/#{node_name}",false)
         node ? node.run_list.recipes : nil
        end

        def get_search_results(search_string,convert_to_hash=true)
          search_results = get_rest("search/#{search_string}",false)
          return nil if search_results.nil?
          return nil unless search_results["rows"]
          convert_to_hash ? search_results["rows"].map{|x|x.to_hash} : search_results["rows"]
        end

        def get_rest(item,convert_to_hash=true)
          raw_rest_results = conn().get_rest(item)
          return raw_rest_results unless convert_to_hash
          raw_rest_results.kind_of?(::Chef::Node) ? raw_rest_results.to_hash : raw_rest_results
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


