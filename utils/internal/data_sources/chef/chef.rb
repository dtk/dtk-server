require 'chef/rest'
require 'chef/config'
require 'mixlib/authentication'

module XYZ
  module DSConnector
    class Chef < Top
      class << self
        def get_objects__component(&block)
          get_cookbook_names().each do |cookbook_name|
            get_recipes_assoc_cookbook(cookbook_name).each do |ds_hash|
              block.call(ds_hash)
            end
          end
          return HashMayNotBeComplete.new()
        end

        def get_objects__assoc_node_component(&block)
          get_node_recipe_assocs().each do |node_name,recipes|
            recipes.each do |recipe|
              ds_hash = DataSourceUpdateHash.new({"node_name" => node_name, "recipe_name" => recipe})
  #TBD: to be used to load in variable values node_attributes = get_node_attributes(node_name)
  #or instead may have discover and update on attributes
              block.call(ds_hash.freeze)
            end
          end
          return HashIsComplete.new()
        end

       private
        #TBD:not needed now
        #def get_node_attributes(node_name)
        #  get_rest("nodes/#{node_name}",false)
        #end

        def get_cookbook_names()
          # get_rest("cookbooks")
          #stub that just gets cookbooks from run list; it actually has recipes so can pass this in too
          get_node_recipe_assocs().values.flatten.map{|x|x.gsub(/::.+$/,"")}.uniq
        end

        def get_metadata(cookbook_name)
          #need version number if 0.9
          cookbook = [cookbook_name]
          if ::Chef::VERSION.to_f >= 0.9
            #need to get meta first
            r = get_rest("cookbooks/#{cookbook_name}")
            #TBD: get max, in case multiple versions; check max is ordering right
            cookbook << r[cookbook_name].max
          end
          r = get_rest("cookbooks/#{cookbook.join('/')}")
          return nil unless r
          r.to_hash["metadata"]
        end

        def get_recipes_assoc_cookbook(cookbook_name)
          metadata = get_metadata(cookbook_name)
          ret = Array.new
          return ret if metadata.nil?

          if metadata["recipes"]
             metadata["recipes"].each do |recipe_name,description|
               #TBD: what to construct so nested and mark attributes as complete
              ds_hash = DataSourceUpdateHash.new({"metadata" => metadata, "name" => recipe_name, "description" => description})
              
              ret << ds_hash.freeze 
             end
          else
            ds_hash = DataSourceUpdateHash.new({"metadata" => metadata, "name" => metadata["name"], "description" => metadata["description"]})
            ret << ds_hash.freeze
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


