module DTK
  class ConfigAgent; module Adapter
    class Puppet < ConfigAgent
      r8_nested_require('puppet','node_manifest')
      # TODO: look at condionally loading parse related files
      r8_nested_require('puppet','parser')
      # parse needs to be before parse_structure
      r8_nested_require('puppet','parse_structure')

      include ParserMixin

      def self.provider_folder
        ProviderFolder
      end
      ProviderFolder = 'puppet'

      def treated_version?(_semantic_version)
        parts = x.split('.')
        return nil unless parts.size == 2 || parts.size == 3
        return nil if parts.find{|p| not (p =~ /^[0-9]$/)}
        first_parts = "#{parts[0]}.#{parts[1]}"
        if match = TreatedVersions[first_parts]
          parts[2].nil? || match.include?(parts[2])
        end
      end
      TreatedVersions = {
        '2.7' => (14..25).map(&:to_s),
        '3.0' => (0..2).map(&:to_s),
        '3.1' => (0..1).map(&:to_s),
        '3.2' => (0..4).map(&:to_s),
        '3.3' => (0..2).map(&:to_s),
        '3.4' => (0..3).map(&:to_s),
        '3.5' => (0..1).map(&:to_s),
        '3.6' => (0..2).map(&:to_s),
        '3.7' => (0..3).map(&:to_s)
      }

      def ret_msg_content(config_node,opts={})
        cmps_with_attrs = components_with_attributes(config_node)
        assembly_attrs = assembly_attributes(config_node)
        puppet_manifests = NodeManifest.new(config_node).generate(cmps_with_attrs,assembly_attrs)
        ret = {
          components_with_attributes: cmps_with_attrs,
          node_manifest: puppet_manifests,
          inter_node_stage: config_node.inter_node_stage(),
          version_context: get_version_context(config_node,opts[:assembly]),
          # TODO: agent not doing puppet version per run; it just can be set when node is created
          puppet_version: config_node[:node][:puppet_version]
        }
        if assembly = opts[:assembly]
          ret.merge!(service_id: assembly.id(), service_name: assembly.get_field?(:display_name))
        end
        ret
      end

      def type
        Type::Symbol.puppet
      end

      # tries to normalize error received from node
      def interpret_error(error_in_result,components)
        ret = error_in_result

        # if ends in 'on node NODEADDR' such as 'on node ip-10-28-77-115.ec2.internal'
        # strip it off because context is not needed and when summarize in node group can use simple test
        # to remove duplicate errors"

        if ret[:message] && ret[:message] =~ /(^.+) on node [^ ]+$/
          ret[:message] = $1
        end

        source = error_in_result['source']
        # working under assumption that stage assignment same as order in components
        if source =~ Regexp.new('^/Stage\\[([0-9]+)\\]')
          index = ($1.to_i) -1
          if cmp_with_error = components[index]
            ret = error_in_result.inject({}) do |h,(k,v)|
              ['source','tags','time'].include?(k) ? h : h.merge(k => v)
            end
            if cmp_name = cmp_with_error[:display_name]
              ret.merge!('component' => cmp_name)
            end
          end
        end
        ret
      end

      def ret_attribute_name_and_type(attribute)
        var_name_path = (attribute[:external_ref]||{})[:path]
        if var_name_path
          array_form = to_array_form(var_name_path)
          {name: array_form && array_form[1], type: type()}
        end
      end

      def ret_attribute_external_ref(hash)
        module_name = hash[:component_type].gsub(/__.+$/,'')
        {
          type: "#{type}_attribute",
          path: "node[#{module_name}][#{hash[:field_name]}]"
        }
      end

      private

      def get_version_context(config_node,assembly_instance)
        ret =  []
        component_actions = config_node[:component_actions]
        if component_actions.empty?()
          return ret
        end
        unless (config_node[:state_change_types] & %w(install_component update_implementation converge_component setting)).size > 0
          return ret
        end

        # want components to be unique
        components = component_actions.inject({}){|h,r|h.merge(r[:component][:id] => r[:component])}.values
        ComponentModule::VersionContextInfo.get_in_hash_form(components,assembly_instance)
      end

      def assembly_attributes(config_node)
        ret = nil
        assembly_attrs = config_node[:assembly_attributes]
        return ret unless assembly_attrs
        assembly_attrs.map do |attr|
          val = ret_value(attr)
          # TODO: hack until can add data types
          val = true if val == 'true'
          val = false if val == 'false'
          {'name' => attr[:display_name], 'value' => val}
        end
      end

      def components_with_attributes(config_node)
        cmp_actions = config_node.component_actions()
        node_components = cmp_actions.map{|ca|(component_external_ref(ca[:component])||{})['name']}.compact
        ndx_cmps = cmp_actions.inject({}) do |h,cmp_action|
          cmp = cmp_action[:component]
          h.merge(cmp[:id] => cmp)
        end
        internal_guards = config_node[:internal_guards]
        if internal_guards.empty?
          attrs_for_guards = nil
        else
          attrs_for_guards = cmp_actions.flat_map{|cmp_action| cmp_action[:attributes]}
        end
        cmp_actions.map do |cmp_action|
          component_with_deps(cmp_action,ndx_cmps).merge(ret_attributes(cmp_action,internal_guards,attrs_for_guards,node_components))
        end
      end

      def component_with_deps(action,ndx_components)
        cmp = action[:component]
        ret = component_external_ref(cmp)
        module_name = ret['name'].gsub(/::.+$/,'')
        ret.merge!('module_name' => module_name)
        cmp_deps = action[:component_dependencies]
        return ret unless cmp_deps and not cmp_deps.empty?
        ret.merge('component_dependencies' => cmp_deps.map{|cmp_id|component_external_ref(ndx_components[cmp_id])})
      end

      def component_external_ref(component)
        ext_ref = component[:external_ref]
        case ext_ref[:type]
         when 'puppet_class'
          {'component_type' => 'class', 'name' => ext_ref[:class_name], 'id' => component[:id]}
         when 'puppet_definition'
          {'component_type' => 'definition', 'name' => ext_ref[:definition_name], 'id' => component[:id]}
         else
          Log.error("unexepected external type #{ext_ref[:type]}")
          nil
        end
      end

      # returns both attributes to set on node and dynmic attributes that get set by the node
      def ret_attributes(action,internal_guards,attrs_for_guards,node_components=nil)
        ndx_attributes = {}
        dynamic_attrs = []
        (action[:attributes]||[]).each do |attr|
          ext_ref = attr[:external_ref]||{}
          if var_name_path = ext_ref[:path]
            array_form_path = to_array_form(var_name_path)
            val = ret_value(attr,node_components)
            # second clause is to handle case where theer is a default just in puppet and header and since not overwritten acts as dynamic attr
            if attr[:value_asserted].nil? && (attr[:dynamic] || ext_ref[:default_variable]) #TODO: the disjunct 'ext_ref[..]' can be deprecated
              dyn_attr = {name: array_form_path[1], id: attr[:id]}
              if ext_ref[:type] == 'puppet_exported_resource'
                type = 'exported_resource'
                dyn_attr.merge!(type: 'exported_resource', title_with_vars: ext_ref[:title_with_vars])
              elsif ext_ref[:default_variable]
                dyn_attr.merge!(type: 'default_variable')
              else
                dyn_attr.merge!(type: 'dynamic')
              end
              if is_connected_output_attribute?(attr)
                dyn_attr.merge!(is_connected: true)
              end
              dynamic_attrs << dyn_attr
            elsif not val.nil?
              add_attribute!(ndx_attributes,array_form_path,val,ext_ref)
              # info that is used to set the name param for the resource
              if rsc_name_path = attr[:external_ref][:name]
                if rsc_name_val = nested_value(val,rsc_name_path)
                  add_attribute!(ndx_attributes,[array_form_path[0],'name'],rsc_name_val,ext_ref)
                end
              end
            elsif guard = internal_guards.find{|g|attr[:id] == g[:guarded][:attribute][:id]}
              val = find_reference_to_guard(guard,attrs_for_guards)
              add_attribute!(ndx_attributes,array_form_path,val,ext_ref) if val
            end
          end
        end
        ret = {}
        ret.merge!('attributes' => ndx_attributes.values) unless ndx_attributes.empty?
        ret.merge!('dynamic_attributes' => dynamic_attrs) unless dynamic_attrs.empty?
        ret
      end

      # TODO: check if this is the right test for connected output attributes
      def is_connected_output_attribute?(attr)
        attr[:port_type] == 'output'
      end

      def ret_value(attr,node_components=nil)
        return node_components if attr[:display_name] == '__node_components' && node_components #TODO: clean-up
        ret = attr[:attribute_value]
        case attr[:data_type]
         when 'boolean'
          if ret == 'true' then ret = true
          elsif ret == 'false' then ret = false
          end
        end
        ret
      end

      def find_reference_to_guard(guard,attributes)
        ret = nil
        unless guard[:link][:function] == 'eq'
          Log.error("not treating internal guards for link fn #{guard[:link][:function]}")
          return ret
        end

        guard_id = guard[:guard][:attribute][:id]
        attr = attributes.find{|attr|attr[:id] == guard_id}
        return nil unless attr
        return nil unless var_name_path = (attr[:external_ref]||{})[:path]
        ref_array_form_path = to_array_form(var_name_path)
        # TODO: case on whether teh ref is computed in first stage or second stage
        {'__ref' => ref_array_form_path}
      end

      # TDOO: may want to better unify how name is passed heer with 'param' and otehr way by setting node path with name last element]
      def nested_value(val,rsc_name_path)
        array_form = rsc_name_path.gsub(/^param\[/,'').gsub(/\]$/,'').split('][')
        nested_value_aux(val,array_form)
      end

      def nested_value_aux(val,array_form,i=0)
        return val unless val.is_a?(Hash)
        return nil if i >= array_form.size
        nested_value_aux(val[array_form[i]],i+1)
      end

      # this is top level; it also class add_attribute_aux for nested values
      def add_attribute!(ndx_attributes,array_form_path_x,val,ext_ref)
        # strip of first element which is module
        array_form_path = array_form_path_x[1..array_form_path_x.size-1]
        extra_info = {}
        ndx = array_form_path.first
        unless ndx_attributes.key?(ndx)
          extra_info =
            case ext_ref[:type]
             when 'puppet_attribute'
              {'type' => 'attribute'}
             when 'puppet_imported_collection'
              {'type' => 'imported_collection',
              'resource_type' =>  ext_ref[:resource_type]}
             else
              raise Error.new("unexpected attribute type (#{ext_ref[:type]})")
            end
        end
        size = array_form_path.size
        if size == 1
          ndx_attributes[ndx] = {'name' => ndx, 'value' => val}.merge(extra_info)
        else
          p = ndx_attributes[ndx] ||= {'name' => ndx, 'value' => {}}.merge(extra_info)
          add_attribute_aux!(p['value'],array_form_path[1..size-1],val)
        end
      end

      def add_attribute_aux!(attr_nested_hash,array_form_path,val)
        size = array_form_path.size
        ndx = array_form_path.first
        if size == 1
          attr_nested_hash[ndx] = val
        else
          attr_nested_hash[ndx] ||= {}
          add_attribute_aux!(attr_nested_hash[ndx],array_form_path[1..size-1],val)
        end
      end

      # TODO: centralize this fn so can be used here and when populate external refs
      # TODO: assume form is node[component][x1] or node[component][x1][x2] or ..
      # service[component][x1] or service[component][x1][x2] or ..
      def to_array_form(external_ref_path)
        # TODO: use regexp disjunction
        external_ref_path.gsub(/^node\[/,'').gsub(/^service\[/,'').gsub(/\]$/,'').split('][')
      end
    end
  end
end; end
