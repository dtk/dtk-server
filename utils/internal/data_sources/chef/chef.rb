require 'chef/rest'
require 'chef/config'
require 'mixlib/authentication'
require 'chef/cookbook/metadata/version'
require  File.expand_path('mixins/metadata', File.dirname(__FILE__))
require  File.expand_path('mixins/assembly', File.dirname(__FILE__))
#TODO: written to get around deficiency that chef get node and searchbrings in full node, not partial info
#TODO: improve meory usage by only storing attributes that are needed
module XYZ
  module DSConnector
    class Chef < Top
      include ChefMixinMetadata
      include ChefMixinAssembly
      def initialize()
        @conn = nil
        @chef_node_cache = Hash.new 
        @cookbook_metadata_cache = Hash.new
        @recipe_service_info_cache =  Hash.new
       @attributes_with_values = Hash.new
      end

      def get_objects__component__instance(&block)
        get_node_recipe_assocs().each do |node_name,recipes|
          recipes.each do |recipe_name|
            node = get_node(node_name)
            metadata = get_metadata_for_recipe(recipe_name)
            next unless metadata
            values = {
              "recipe_name" => recipe_name, 
              "node_name" => node_name,
              "basic_type" => metadata["basic_type"]
            }

            attributes = get_attributes_with_values(recipe_name,metadata,node)
            ds_hash = DataSourceUpdateHash.new(values.merge({"attributes" => attributes}))
            block.call(ds_hash)
          end
        end
        return HashMayNotBeComplete.new() #HashIsComplete.new()
      end

      def get_objects__component__recipe(&block)
        get_cookbook_names().each do |cookbook_name|
          get_recipes_assoc_cookbook(cookbook_name).each do |ds_hash|
           block.call(ds_hash)
          end
        end
        return HashIsComplete.new() #HashMayNotBeComplete.new()
      end

      def get_recipes_assoc_cookbook(cookbook_name)
        ret = Array.new
        recipes = get_cookbook_recipes_metadata(cookbook_name)
        return ret unless recipes

        recipes.each do |recipe_name,description|
          metadata = get_metadata_for_recipe(recipe_name)
          next unless metadata
          values = {
            "recipe_name" => recipe_name, 
            "description" => description,
            "basic_type" => metadata["basic_type"]
          }
          monitoring_items = get_monitoring_items(metadata)
          attributes =  get_attributes_with_values(recipe_name,metadata)
          #TODO: what to construct so nested and mark attributes as complete
          ds_hash = DataSourceUpdateHash.new(values.merge({"attributes" => attributes, "monitoring_items" => monitoring_items}))
          ret << ds_hash.freeze 
        end
        ret
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
        
     private
      def get_node(node_name)
        @chef_node_cache[node_name] ||= filter_to_only_relevant(get_rest("nodes/#{node_name}",false))
      end

      #TODO: stub
      def filter_to_only_relevant(node)
        node
      end

      def get_cookbook_names()
        # get_rest("cookbooks")
        #stub that just gets cookbooks from run list; it actually has recipes so can pass this in too
        get_node_recipe_assocs().values.flatten.map{|x|x.gsub(/::.+$/,"")}.uniq
      end

      def get_cookbook_recipes_metadata(cookbook_name)
        (get_metadata_for_cookbook(cookbook_name)||{})["recipes"]
      end

      def get_metadata_for_recipe(recipe_name)
        cookbook_metadata = get_metadata_for_cookbook(get_cookbook_name_from_recipe_name(recipe_name))
        return nil if cookbook_metadata.nil?
        @recipe_service_info_cache[recipe_name] ||= get_component_services_info(recipe_name,cookbook_metadata)
        basic_type = (cookbook_metadata["basic_types"]||{})[recipe_name]
        cookbook_metadata.merge({"services_info" => @recipe_service_info_cache[recipe_name],"basic_type" => basic_type})
      end

      def get_metadata_for_cookbook(cookbook_name)
       @cookbook_metadata_cache[cookbook_name] ||= get_metadata_aux(cookbook_name)
      end

      def get_metadata_aux(cookbook_name)
        #need version number if 0.9
        cookbook = [cookbook_name]
        if ChefVersion.current >= ChefVersion["0.9.0"]
          #need to get meta first
          r = get_rest("cookbooks/#{cookbook_name}")
          return nil unless r
          #get max, in case multiple versions
          cookbook << r[cookbook_name].map{|x|ChefVersion[x]}.max.chef_version
        end

        r = get_rest("cookbooks/#{cookbook.join('/')}")
        return nil unless r
        ret=process_raw_metadata!(r.to_hash["metadata"])
        remove_subsuming_attributes!(ret)
      end


      #removes attributes like foo when teher also exists foo/k1, foo/k2
      def remove_subsuming_attributes!(metadata)
        return metadata unless metadata and metadata["attributes"]
        keys = metadata["attributes"].keys
        return metadata if keys.empty?
        metadata["attributes"].reject!{|k,v| keys.find{|k2| k2 =~ Regexp.new("^#{k}.")}}
        metadata
      end


      def get_cookbook_name_from_recipe_name(recipe_name)
        recipe_name.gsub(/::.+/,"")
      end

      def get_monitoring_items(metadata)
        ret = Hash.new
        return ret unless metadata
        (metadata["services_info"]||[]).map{|s|(s[:conditions]||[]).map{|c|c[:to_monitor].map{|x|
              next unless x[:name]
              ret[x[:name]] = x.merge({:service_name => s[:canonical_service_name],
                        :condition_name => c[:name],
                        :condition_description => c[:description],
                        :enabled => true})
            }}}
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
        @chef_node_cache.each{|node_name,node|recipes[node_name] = recipes(node)}
        recipes
      end

      def get_node_recipes(node_name)
        node = get_node(node_name)
        node ? recipes(node) : nil
      end

      def get_search_results(search_string,convert_to_hash=true)
        search_results = get_rest("search/#{search_string}",false)
        return nil if search_results.nil?
        return nil unless search_results["rows"]
        convert_to_hash ? search_results["rows"].map{|x|x.to_hash} : search_results["rows"]
      end

      def get_rest(item,convert_to_hash=true)
        raw_rest_results = nil
        begin 
          raw_rest_results = conn().get_rest(item)
         rescue Exception => e
          Log.debug_pp [:error,e]
        end
        return raw_rest_results if raw_rest_results.nil?
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
        #Mixlib::Authentication is a gem provided vy Opscode
        ::Mixlib::Authentication::Log.logger = ::Chef::Log.logger
        ::Chef::REST.new(::Chef::Config[:chef_server_url], ::Chef::Config[:node_name],::Chef::Config[:client_key])
      end

      #if node is nil means that getting info just from metadata
      def get_attributes_with_values(recipe_name,metadata,node=nil)
        index = node ? node.name : :recipe
        @attributes_with_values[index] ||= Hash.new
        @attributes_with_values[index][recipe_name] ||= get_attributes_with_values_aux(recipe_name,metadata,node)
      end

      def get_attributes_with_values_aux(recipe_name,metadata,node=nil)
        ret = HashObject.create_with_auto_vivification()
        (metadata["attributes"]||{}).each do |raw_attr_name,attr_metadata| 
          recipes = attr_metadata["recipes"]||[]
          next unless recipes.empty? or recipes.include?(recipe_name)
          attr_name,service_name = get_attribute_and_service_names(raw_attr_name)
          ret[attr_name] = attr_metadata.dup
          ret[attr_name]["service_name"] = service_name if service_name
          #TODO: for testing port type
          unless (metadata["attributes"]||{}).find{|a,m|m["port_type"]}
            port_type = ["","input","output"][attr_name[0].modulo(3)]
            ret[attr_name]["port_type"] = port_type unless port_type.empty?
          end
          ##############
          set_attribute_value(ret,attr_name,attr_metadata,metadata,node)
        end
        ret.freeze
      end
    
      def set_attribute_value(ret,attr_name,attr_metadata,metadata,node=nil)
        return set_service_attribute_value(ret,attr_name,attr_metadata,metadata,node) if attr_metadata["is_service_attribute"]
        value =
          if node.nil?
            attr_metadata["default"]
          else
            attribute_path = attr_name.split("/")
            first = attribute_path.shift
            value_x = NodeState.nested_value(node[first],attribute_path)
            value_x.kind_of?(::Chef::Node::Attribute) ? value_x.to_hash : value_x
          end
        ret[attr_name]["value"] = value if value
        value
      end

      def set_service_attribute_value(ret,attr_name,attr_metadata,metadata,node=nil)
        return nil unless attr_metadata["transform"]
        #  e.g., transform  {"__ref"=>"node[hadoop][jmxremote][password]"} to
        #        {"external_ref"=>{"type"=>"chef_attribute", "ref"=>"node[hadoop][jmxremote][password]"}}
        transform = ret_normalized_transform_info(attr_metadata["transform"])
        if node
          normalize_attribute_values(ret[attr_name],{"value" => transform},node)
        else
          normalize_attribute_values(ret[attr_name],{"value" => transform},node,metadata)
        end
        ret[attr_name].has_key?("value") ? ret[attr_name]["value"] : nil
      end

      def recipes(node)
        node.run_list ? node.run_list.recipes : nil
      end

      class ChefVersion
        attr_reader :chef_version
        def initialize(chef_version=::Chef::VERSION)
          @chef_version = chef_version
        end
        def self.current()
          ChefVersion.new
        end
        def self.[](chef_version)
          ChefVersion.new(chef_version)
        end

        def <=>(cv)
          #assume form is "x.y.z"
          v1 = self.chef_version.split(".").map{|x|x.to_i}
          v2 = cv.chef_version.split(".").map{|x|x.to_i}
          for i in 0..2
            ret = v1[i] <=> v2[i]
            return ret unless ret == 0
          end
          return 0
        end
        def >=(cv)
          (self <=>(cv)) >= 0
        end
      end
    end
  end
end


