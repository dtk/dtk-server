# TODO!!!: only need to pass params of cookbook included
# TODO: need to be more sophsicticated on what recipes included (or take simple approach and include all)
# for example need to include ones in same cookbook; may also want to include cookbook fro monitoring post check
# TODO: can modify to make more efficient by having single db call
# TODO: minimal conversion from form where just had change attributes; so room to simplify and make more efficient
module XYZ
  class ConfigAgent; module Adapter
    class Chef < ConfigAgent
      def ret_msg_content(config_node)
        recipes_and_attrs = Processor.new(config_node)
        {:attributes => recipes_and_attrs.attributes, :run_list => recipes_and_attrs.run_list}
      end
      def type()
        :chef
      end
      def ret_attribute_name_and_type(attribute)
        var_name_path = (attribute[:external_ref]||{})[:path]
        if var_name_path 
          array_form = to_array_form(var_name_path)
          {:name => array_form && array_form[1], :type => type()}
        end
      end

      def ret_attribute_external_ref(hash)
        module_name = hash[:component_type].gsub(/__.+$/,"")
        {
          :type => "#{type}_attribute",
          :path =>  "node[#{module_name}][#{hash[:field_name]}]"
        }             
      end

     private
      # TODO: collapse with other versions of this
      def to_array_form(external_ref_path,opts={})
        # TODO: use regexp disjunction
        ret = external_ref_path.gsub(/^node\[/,"").gsub(/^service\[/,"").gsub(/\]$/,"").split("][")
        ret.shift if opts[:strip_off_recipe_name]
        ret
      end

      class Processor 
        attr_reader :attributes
        def initialize(config_node)
          # TODO: need to preserve order; only complication is removing duplicates
          @recipe_names = config_node.component_actions().map{|cmp_action|recipe(cmp_action[:component])}.uniq
          @common_attr_index = Hash.new
          @attributes = Hash.new
          cmps_on_node = config_node[:node].get_children_objs(:component,{:cols=>[:id,:external_ref,:only_one_per_node]})
          cmps_on_node.each{|cmp|add_action(cmp)}
        end

        def run_list()
          @recipe_names.map{|r|"recipe[#{r}]"}
        end

        def add_action(component)
          recipe_name = recipe(component)
          if @common_attr_index[recipe_name]
            common_attr_val_list = @common_attr_index[recipe_name]
            common_attr_val_list << ret_attributes(component, :strip_off_recipe_name => true)
          elsif component[:only_one_per_node]
            deep_merge!(@attributes,ret_attributes(component))
          else
            list = Array.new
            @common_attr_index[recipe_name] = list
            list << ret_attributes(component, :strip_off_recipe_name => true)
            if recipe_name =~ /(^.+)::(.+$)/
              cookbook_name = $1
              rcp_name = $2
              deep_merge!(@attributes,{cookbook_name => {rcp_name => {"!replace:list" => list}}})
            else
              deep_merge!(@attributes,{recipe_name => {"!replace:list" => list}})
            end
          end
          self
        end
       private
        def deep_merge!(target,source)
          source.each do |k,v|
            if target.has_key?(k)
              deep_merge!(target[k],v)
            else
              target[k] = v
            end
          end
        end

        def recipe(component)
          (component[:external_ref]||{})[:recipe_name]
        end
        def ret_attributes(component,opts={})
          ret = Hash.new
          attrs = component.get_children_objs(:attribute,{:cols=>[:external_ref,:attribute_value]})
          attrs.each do |attr|
            var_name_path = (attr[:external_ref]||{})[:path]
            val = attr[:attribute_value]
            add_attribute!(ret,to_array_form(var_name_path,opts),val) if var_name_path
          end
          ret
        end

        def add_attribute!(ret,array_form_path,val)
          size = array_form_path.size
          if size == 1
          # TODO: after testing remove setting nils
            ret[array_form_path.first] = val
          else
            ret[array_form_path.first] ||= Hash.new
            add_attribute!(ret[array_form_path.first],array_form_path[1..size-1],val)
          end
        end

        # TODO: centralize this fn so can be used here and when populate external refs
          # TODO: assume form is node[recipe][x1] or node[recipe][x1][x2] or ..
          # service[recipe][x1] or service[recipe][x1][x2] or ..
        def to_array_form(external_ref_path,opts)
          # TODO: use regexp disjunction
          ret = external_ref_path.gsub(/^node\[/,"").gsub(/^service\[/,"").gsub(/\]$/,"").split("][")
          ret.shift if opts[:strip_off_recipe_name]
          ret
        end
      end
    end
  end
end
