require 'chef/rest'
require 'chef/config'
require 'mixlib/authentication'
require 'chef/cookbook/metadata/version'

#TODO: written to get around deficiency that chef get node and searchbrings in full node, not partial info
#TODO: imporve meory usage by only storing attributes that are needed
module XYZ
  module DSConnector
    class Chef < Top
      def initialize()
        @conn = nil
        @chef_node_cache = Hash.new
      end
      def get_objects__component__recipe(&block)
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
  #TODO: to be used to load in variable values node_attributes = get_node_attributes(node_name)
  #or instead may have discover and update on attributes
            block.call(ds_hash.freeze)
          end
        end
        return HashIsComplete.new()
      end
        
      def chef_version()
         ::Chef::VERSION.to_f 
      end
     private
      def get_node(node_name)
        @chef_node_cache[node_name] ||= get_rest("nodes/#{node_name}",false)
      end

      def get_cookbook_names()
        # get_rest("cookbooks")
        #stub that just gets cookbooks from run list; it actually has recipes so can pass this in too
        get_node_recipe_assocs().values.flatten.map{|x|x.gsub(/::.+$/,"")}.uniq
      end

      def get_metadata(cookbook_name)
        #need version number if 0.9
        cookbook = [cookbook_name]
        if chef_version >= 0.9

          #need to get meta first
          r = get_rest("cookbooks/#{cookbook_name}")
          #TODO: get max, in case multiple versions; check max is ordering right
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
            #TODO: what to construct so nested and mark attributes as complete
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
        #TODO: may be better to make rest call per node or use chef iterator functionality
        search_string = "node?q=*:*"
        unless @chef_node_cache.empty?
          search_string = "node?q="+@chef_node_cache.keys.map{|n|"NOT%20name:#{n}"}.join("%20AND%20")
        end
        (get_search_results(search_string,false)||[]).map do |node|
          @chef_node_cache[node.name] = node
        end
        @chef_node_cache.each{|node_name,node|recipes[node_name] = node.run_list.recipes}
        recipes
      end

      def get_node_recipes(node_name)
        node = get_node(node_name)
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
        return raw_rest_results if raw_rest_results.kind_of?(Hash)
        raw_rest_results.to_hash 
      end

      def conn()
        @conn ||=  initialize_chef_connection()
      end

      def initialize_chef_connection()
        ::Chef::Config.from_file("/root/.chef/knife.rb") #TODO: stub; will replace by passing in relavant paramters
        ::Chef::Log.level(::Chef::Config[:log_level])
#What is mixlib?
        ::Mixlib::Authentication::Log.logger = ::Chef::Log.logger
        ::Chef::REST.new(::Chef::Config[:chef_server_url], ::Chef::Config[:node_name],::Chef::Config[:client_key])
      end
    end
  end
end


