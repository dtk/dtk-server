require 'chef/rest'
require 'chef/config'
require 'mixlib/authentication'
require 'chef/cookbook/metadata/version'
require File.expand_path('mixins/metadata', File.dirname(__FILE__))
require File.expand_path('mixins/assembly', File.dirname(__FILE__))
# TODO: written to get around deficiency that chef get node and searchbrings in full node, not partial info
# TODO: improve memory usage by only storing attributes that are needed
module XYZ
  module DSConnector
    class Chef < Top
      include ChefMixinMetadata
      include ChefMixinAssembly
      def initialize_extra
        @conn = nil
        @chef_node_cache = Aux::Cache.new
        @cookbook_metadata_cache = Aux::Cache.new
        @recipe_service_info_cache =  Aux::Cache.new
        @attributes_with_values = Aux::Cache.new
      end

      def get_objects__node(&block)
        get_nodes().each do |node_name, node|
          node_properties = %w(node_display_name lsb)
          ds_hash = DataSourceUpdateHash.new({ 'node_name' => node_name })
          node_properties.each do |attr|
            next unless value = node[attr]
            ds_hash[attr] = value.respond_to?(:to_hash) ? value.to_hash : value
          end
          ds_hash.merge!({ 'components' => get_node_components(node) })

          block.call(ds_hash.freeze)
        end
        HashMayNotBeComplete.new()
      end

      def get_objects__component__recipe(&block)
        get_cookbook_names().each do |cookbook_name|
          get_recipes_assoc_cookbook(cookbook_name).each do |ds_hash|
            block.call(ds_hash)
          end
        end
        HashIsComplete.new({ type: 'template' }) #HashMayNotBeComplete.new()
      end

      private

      def get_node_components(node)
        ret = DataSourceUpdateHash.new
        (recipes(node) || []).each do |recipe_name|
          metadata = get_metadata_for_recipe(recipe_name)
          next unless metadata
          ref = recipe_name
          values = {
            'normalized_recipe_name' => normalized_recipe_name(recipe_name),
            'recipe_name' => recipe_name,
            'basic_type' => metadata['basic_type'],
            'node_name' => node.name
          }
          attrs = get_attributes_with_values(recipe_name, metadata, node)
          ret[ref] = DataSourceUpdateHash.new(values.merge({ 'attributes' => attrs }))
        end
        ret
      end

      def get_recipes_assoc_cookbook(cookbook_name)
        ret = []
        recipes = get_cookbook_recipes_metadata(cookbook_name)
        return ret unless recipes

        recipes.each do |recipe_name, description|
          metadata = get_metadata_for_recipe(recipe_name)
          next unless metadata
          values = {
            'normalized_recipe_name' => normalized_recipe_name(recipe_name),
            'recipe_name' => recipe_name,
            'description' => description,
            'basic_type' => metadata['basic_type']
          }
          mons = get_monitoring_items(metadata)
          attrs =  get_attributes_with_values(recipe_name, metadata)
          ds_hash = DataSourceUpdateHash.new(values.merge({ 'attributes' => attrs, 'monitoring_items' => mons }))
          ret << ds_hash.freeze
        end
        ret
      end

      def normalized_recipe_name(recipe_name)
        return Regexp.last_match(1) if recipe_name =~ /(^.+)::default/
        recipe_name.gsub(/::/, Model::Delim::Common)
      end

      def get_node(node_name)
        @chef_node_cache[node_name] ||= filter_to_only_relevant(get_rest("nodes/#{node_name}", false))
      end

      def get_nodes
        # TODO: may be better to make rest call per node or use chef iterator functionality
        # TODO": this is increemntal yupdate; wil wil be in context where this is needed?
        search_string = 'node?q=*:*'
        unless @chef_node_cache.empty?
          search_string = 'node?q=' + @chef_node_cache.keys.map { |n| "NOT%20name:#{n}" }.join('%20AND%20')
        end
        (get_search_results(search_string, false) || []).map do |node|
          @chef_node_cache[node.name] = node
        end
        @chef_node_cache
      end

      def get_node_recipe_assocs
        ret = {}
        get_nodes().each { |node_name, node| ret[node_name] = recipes(node) }
        ret
      end

      def get_node_recipes(node_name)
        node = get_node(node_name)
        node ? recipes(node) : nil
      end

      # TODO: stub
      def filter_to_only_relevant(node)
        node
      end

      def get_cookbook_names
        # get_rest("cookbooks")
        # stub that just gets cookbooks from run list; it actually has recipes so can pass this in too
        get_node_recipe_assocs().values.flatten.map { |x| x.gsub(/::.+$/, '') }.uniq
      end

      def get_cookbook_recipes_metadata(cookbook_name)
        (get_metadata_for_cookbook(cookbook_name) || {})['recipes']
      end

      def get_metadata_for_recipe(recipe_name)
        cookbook_metadata = get_metadata_for_cookbook(get_cookbook_name_from_recipe_name(recipe_name))
        return nil if cookbook_metadata.nil?
        @recipe_service_info_cache[recipe_name] ||= get_component_services_info(recipe_name, cookbook_metadata)
        basic_type = (cookbook_metadata['basic_types'] || {})[recipe_name]
        cookbook_metadata.merge({ 'services_info' => @recipe_service_info_cache[recipe_name], 'basic_type' => basic_type })
      end

      def get_metadata_for_cookbook(cookbook_name)
       @cookbook_metadata_cache[cookbook_name] ||= get_metadata_aux(cookbook_name)
      end

      def get_metadata_aux(cookbook_name)
        # need version number if 0.9
        cookbook = [cookbook_name]
        if ChefVersion.current >= ChefVersion['0.9.0']
          # need to get meta first
          r = get_rest("cookbooks/#{cookbook_name}")
          return nil unless r
          # get max, in case multiple versions
          cookbook << r[cookbook_name].map { |x| ChefVersion[x] }.max.chef_version
        end

        r = get_rest("cookbooks/#{cookbook.join('/')}")
        return nil unless r
        ret = process_raw_metadata!(r.to_hash['metadata'])
        remove_subsuming_attributes!(ret)
      end

      # removes attributes like foo when teher also exists foo/k1, foo/k2
      def remove_subsuming_attributes!(metadata)
        return metadata unless metadata and metadata['attributes']
        exploded_keys = metadata['attributes'].keys.map { |x| x.split('/') }
        return metadata if exploded_keys.empty?
        metadata['attributes'].reject! do |k, _v|
          ek = k.split('/')
          exploded_keys.find { |k2| ek.size < k2.size and ek == k2[0..ek.size - 1] }
        end
        metadata
      end

      def get_cookbook_name_from_recipe_name(recipe_name)
        recipe_name.gsub(/::.+/, '')
      end

      def get_monitoring_items(metadata)
        ret = {}
        return ret unless metadata
        (metadata['services_info'] || []).map {|s| (s[:conditions] || []).map {|c| c[:to_monitor].map {|x|
              next unless x[:name]
              ret[x[:name]] = x.merge({ service_name: s[:canonical_service_name],
                                        condition_name: c[:name],
                                        condition_description: c[:description],
                                        enabled: true })
            }}}
        ret
      end

      MaxRows = 1000
      def get_search_results(search_string, convert_to_hash = true)
        #        search_results = get_rest("search/#{search_string}",false) TODO: check if below only works with 9.x
        search_results = get_rest("search/#{search_string}&start=0&rows=#{MaxRows}", false)
        return nil if search_results.nil?
        return nil unless search_results['rows']
        convert_to_hash ? search_results['rows'].map(&:to_hash) : search_results['rows']
      end

      def get_rest(item, convert_to_hash = true)
        raw_rest_results = nil
        begin
          raw_rest_results = conn().get_rest(item)
         rescue Exception => e
          Log.debug_pp [:error, e]
        end
        return raw_rest_results if raw_rest_results.nil?
        return raw_rest_results unless convert_to_hash
        return raw_rest_results if raw_rest_results.is_a?(Hash)
        raw_rest_results.to_hash
      end

      def conn
        @conn ||= initialize_chef_connection()
      end

      def initialize_chef_connection
        ::Chef::Config.from_file('/root/.chef/knife.rb') #TODO: stub; will replace by passing in relavant paramters
        ::Chef::Log.level(::Chef::Config[:log_level])
        # Mixlib::Authentication is a gem provided vy Opscode
        ::Mixlib::Authentication::Log.logger = ::Chef::Log.logger
        ::Chef::REST.new(::Chef::Config[:chef_server_url], ::Chef::Config[:node_name], ::Chef::Config[:client_key])
      end

      # if node is nil means that getting info just from metadata
      def get_attributes_with_values(recipe_name, metadata, node = nil)
        index = node ? node.name : :recipe
        @attributes_with_values[index] ||= {}
        @attributes_with_values[index][recipe_name] ||= get_attributes_with_values_aux(recipe_name, metadata, node)
      end

      def get_attributes_with_values_aux(recipe_name, metadata, node = nil)
        ret = DataSourceUpdateHash.create()
        (metadata['attributes'] || {}).each do |raw_attr_name, attr_metadata|
          recipes = attr_metadata['recipes'] || []
          next unless recipes.empty? or recipes.include?(recipe_name)
          attr_name, service_name = get_attribute_and_service_names(raw_attr_name)
          ret[attr_name] = attr_metadata.dup #TODO: dont think dup is needed
          ret[attr_name]['service_name'] = service_name if service_name
          ret[attr_name]['is_port'] = (service_name ? true : false)
          ##############
          set_attribute_value(ret, attr_name, attr_metadata, metadata, node)
        end

        ret.freeze
      end

      def set_attribute_value(ret, attr_name, attr_metadata, metadata, node = nil)
        return set_service_attribute_value(ret, attr_name, attr_metadata, metadata, node) if attr_metadata['is_service_attribute']
        value =
          if node.nil?
            attr_metadata['default']
          else
            attribute_path = attr_name.split('/')
            first = attribute_path.shift
            value_x = NodeState.nested_value(node[first], attribute_path)
            value_x.is_a?(::Chef::Node::Attribute) ? value_x.to_hash : value_x
          end
        ret[attr_name]['value'] = value if value
        value
      end

      def set_service_attribute_value(ret, attr_name, attr_metadata, metadata, node = nil)
        return nil unless attr_metadata['transform']
        #  e.g., transform  {"__ref"=>"node[hadoop][jmxremote][password]"} to
        #        {"external_ref"=>{"type"=>"chef_attribute", "ref"=>"node[hadoop][jmxremote][password]"}}
        transform = ret_normalized_transform_info(attr_metadata['transform'])
        if node
          normalize_attribute_values(ret[attr_name], { 'value' => transform }, node)
        else
          normalize_attribute_values(ret[attr_name], { 'value' => transform }, node, metadata)
        end
        ret[attr_name].key?('value') ? ret[attr_name]['value'] : nil
      end

      def recipes(node)
        node.run_list ? node.run_list.recipes : nil
      end

      class ChefVersion
        attr_reader :chef_version
        def initialize(chef_version = ::Chef::VERSION)
          @chef_version = chef_version
        end
        def self.current
          ChefVersion.new
        end
        def self.[](chef_version)
          ChefVersion.new(chef_version)
        end

        def <=>(cv)
          # assume form is "x.y.z"
          v1 = self.chef_version.split('.').map(&:to_i)
          v2 = cv.chef_version.split('.').map(&:to_i)
          for i in 0..2
            ret = v1[i] <=> v2[i]
            return ret unless ret == 0
          end
          0
        end

        def >=(cv)
          (self <=> (cv)) >= 0
        end
      end
    end
  end
end
