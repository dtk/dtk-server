module Ramaze::Helper
  module AssemblyHelper
    r8_nested_require('assembly_helper','action')
    include ActionMixin

    def ret_assembly_object
      assembly_id,subtype = ret_assembly_params_id_and_subtype()
      id_handle(assembly_id,:component).create_object(model_name: (subtype == :instance) ? :assembly_instance : :assembly_template)
    end

    def ret_assembly_params_object_and_subtype
      assembly_id,subtype = ret_assembly_params_id_and_subtype()
      obj = id_handle(assembly_id,:component).create_object(model_name: (subtype == :instance) ? :assembly_instance : :assembly_template)
      [obj,subtype]
    end

    def ret_workspace_object?(id_param=nil,_opts={})
      ret_assembly_instance_or_workspace_object?(id_param,only_workspace: true)
    end

    def ret_assembly_instance_or_workspace_object?(id_param=nil,opts={})
      assembly_instance = ret_assembly_instance_object(id_param)
      if ::DTK::Workspace.is_workspace?(assembly_instance)
        assembly_instance.id_handle().create_object(model_name: :assembly_workspace)
      else
        if opts[:only_workspace]
          raise ::DTK::ErrorUsage.new("The command can ony be applied to a workspace")
        end
        assembly_instance
      end
    end

    def ret_assembly_instance_object?(id_param=nil)
      id_param ||= :assembly_id
      if assembly_id = ret_request_param_id?(id_param,::DTK::Assembly::Instance)
        id_handle(assembly_id,:component).create_object(model_name: :assembly_instance)
      end
    end

    def ret_assembly_instance_object(id_param=nil)
      id_param ||= :assembly_id
      assembly_id = ret_request_param_id(id_param,::DTK::Assembly::Instance)
      id_handle(assembly_id,:component).create_object(model_name: :assembly_instance)
    end

    def ret_assembly_template_object(id_param=nil)
      id_param ||= :assembly_id
      assembly_id = ret_request_param_id(id_param,::DTK::Assembly::Template)
      id_handle(assembly_id,:component).create_object(model_name: :assembly_template)
    end

    def ret_assembly_params_id_and_subtype
      subtype = (ret_request_params(:subtype)||:instance).to_sym
      assembly_id = ret_request_param_id(:assembly_id,subtype == :instance ? ::DTK::Assembly::Instance : ::DTK::Assembly::Template)
      [assembly_id,subtype]
    end

    def ret_assembly_subtype
      (ret_request_params(:subtype)||:instance).to_sym
    end

    def ret_port_object(param,assembly_idh,conn_type)
      extra_context = {assembly_idh: assembly_idh,connection_type: conn_type}
      create_obj(param,::DTK::Port,extra_context)
    end

    ### methods to return components
    def ret_component_instance(_param,assembly)
      ret_component_id_handle(:component_id,assembly).create_object()
    end

    def ret_component_id_handle(param,assembly)
      id = ret_component_id(param,assembly)
      id_handle(id,:component_instance)
    end

    def ret_component_id?(param,assembly)
      if ret_request_params(param)
        ret_component_id(param,assembly)
      end
    end

    def ret_component_id(param,assembly)
      ret_request_param_id(param,::DTK::Component,assembly_id: assembly.id())
    end
    private :ret_component_id
    ### end: methods to return components

    def ret_node_id(node_name_param,assembly)
      ret_node_id_handle(node_name_param,assembly).get_id()
    end

    def ret_node_id_handle(node_name_param,assembly)
      ret_request_param_id_handle(node_name_param,::DTK::Node,assembly.id())
    end

    def ret_node_or_group_member_id_handle(node_name_param,assembly)
      node_name_or_id = ret_non_null_request_params(:node_id)
      if node_name_or_id =~ /^[0-9]+$/
        ret_request_param_id_handle(node_name_param,::DTK::Node,assembly.id())
      else
        nodes = assembly.info_about(:nodes)
        matching_nodes = nodes.select{|node| node[:display_name].eql?(node_name_or_id)}

        matching_id =
          if matching_nodes.size == 1
            matching_nodes.first[:id]
          elsif matching_nodes.size > 2
            raise ::DTK::ErrorNameAmbiguous.new(node_name_or_id,matching_nodes.map{|r|r[:id]},:node)
          else
            raise ::DTK::ErrorNameDoesNotExist.new(node_name_or_id,:node)
          end

        id_handle(matching_id,:node)
      end
    end

    ##
    # Pass param name containing with comma seperated names or ids. Param name should
    # resolve to command seperated node id/names (String)
    #
    # Returns: Returns array of node id handles
    #
    def ret_node_id_handles(node_name_param, assembly)
      Log.error("check if works for node groups")
      # get nodes list (command seperated) from request
      target_nodes_str = ret_request_params(node_name_param)
      return [] unless target_nodes_str
      # if node names exist, split them and remove extra spaces
      target_nodes = target_nodes_str.split(',').collect do |node_name|
        ret_id_handle_from_value(node_name.strip, ::DTK::Node, assembly.id())
      end

      target_nodes
    end

    # assuming that service link is identified by either
    #:service_link_id or
    #:service_type and :input_component_id or
    #:dependency_type, :input_component_id, and :output_component_id
    def ret_port_link(assembly=nil)
      assembly ||= ret_assembly_instance_object()
      if ret_request_params(:service_link_id)
        create_obj(:service_link_id,::DTK::PortLink,assembly_idh: assembly.id_handle())
      else
        filter =  {input_component_id: ret_component_id(:input_component_id,assembly)}
        if service_type = (ret_request_params(:dependency_name)||ret_request_params(:service_type))
          filter.merge!(service_type: service_type)
        end
        if ret_request_params(:output_component_id)
          filter.merge!(output_component_id: ret_component_id(:output_component_id,assembly))
        end
        assembly.get_matching_port_link(filter)
      end
    end

    # validates param_settings and returns array of setting objects
    # order determines order it is applied
    def ret_settings_objects(assembly_template)
      ret = ::DTK::ServiceSetting::Array.new()
      unless param_settings_json = ret_request_params(:settings_json_form)
        return ret
      end
      param_settings = ::DTK::Aux.json_parse(param_settings_json)

      # indexed by display_name
      ndx_existing_settings = assembly_template.get_settings().inject({}) do |h,s|
        h.merge(s[:display_name] => s)
      end
      bad_settings = []
      param_settings.each do |param_setting|
        unless setting_name = param_setting['name']
          raise ::DTK::ErrorUsage.new("Ill-formed service settings string")
        end
        if setting = ndx_existing_settings[setting_name]
          if parameters = param_setting['parameters']
            setting.bind_parameters!(parameters)
          end
          ret << setting
        else
          bad_settings << setting_name
        end
      end
      unless bad_settings.empty?
        raise ::DTK::ErrorUsage.new("Provided service settings (#{bad_settings.join(',')}) are not defined; legal settings are: #{ndx_existing_settings.keys.join(',')}")
      end
      ret
    end

    # returns [assembly_template_name,service_module_name]; if cannot find one or both or these nil is returned in the associated element
    def get_template_and_service_names_params(assembly)
      assembly_template_name,service_module_name = ret_request_params(:assembly_template_name,:service_module_name)
      module_namespace = nil
      # either they both should be null or neither; however using 'or', rather than 'and' for robustness
      if assembly_template_name.nil? || service_module_name.nil?
        if parent_template = assembly.get_parent()
          assembly_template_name = parent_template[:display_name]
          if service_module = parent_template.get_service_module()
            service_module_name = service_module[:display_name]
            service_module.update_object!(:namespace)
            module_namespace = service_module[:namespace][:name]
          end
        end
      end
      [assembly_template_name,service_module_name,module_namespace]
    end
  end

  def ret_attribute_settings_hash
    yaml_content = ret_non_null_request_params(:settings_yaml_content)
    response = ::DTK::Aux.convert_to_hash( yaml_content ,:yaml)
    process_attributes!(response)
    raise response if response.is_a?(::DTK::Error)
    response
  end

  def process_attributes!(response)
    # we are assigning assembly wide components to assembly wide node
    response['assembly_wide/'] = response.delete('components') if response.key?('components')

    nodes = response.delete('nodes')||{}
    nodes.each do |n_name, node|
      node_cmps = node.delete('components')||{}
      nodes[n_name] = node_cmps
      node_cmps.each do |cmp_name, n_cmp|
        n_cmp_attrs = n_cmp.delete('attributes')||{}
        nodes[n_name][cmp_name] = n_cmp_attrs
      end

      node_attrs = node.delete('attributes')||{}
      nodes[n_name].merge!(node_attrs)
    end

    assembly_wide = response.delete('assembly_wide/')||{}
    assembly_wide.each do |cmp_name, n_cmp|
      n_cmp_attrs = n_cmp.delete('attributes')||{}
      assembly_wide[cmp_name] = n_cmp_attrs
    end

    response.merge!(nodes) if nodes
    response.merge!(assembly_wide) if assembly_wide
    response
  end

      def info_about_filter
      end

    # checks element through set of fields
    def element_matches?(element,path_array, element_id_val)
      return true if (element_id_val.nil? || element_id_val.empty?)
      return false if element.nil?
      temp_element = element
        path_array.each do |field|
        temp_element = temp_element[field]
        return false if temp_element.nil?
      end
      temp_element == element_id_val.to_i
    end
end

