module Ramaze::Helper
  module AssemblyHelper
    def ret_assembly_object()
      assembly_id,subtype = ret_assembly_params_id_and_subtype()
      id_handle(assembly_id,:component).create_object(:model_name => (subtype == :instance) ? :assembly_instance : :assembly_template) 
    end
    def ret_assembly_params_object_and_subtype()
      assembly_id,subtype = ret_assembly_params_id_and_subtype()
      obj = id_handle(assembly_id,:component).create_object(:model_name => (subtype == :instance) ? :assembly_instance : :assembly_template) 
      [obj,subtype]
    end

    def ret_workspace_object?(id_param=nil,opts={})
      ret_assembly_instance_or_workspace_object?(id_param,:only_workspace=>true)
    end
    def ret_assembly_instance_or_workspace_object?(id_param=nil,opts={})
      assembly_instance = ret_assembly_instance_object(id_param)
      if ::DTK::Workspace.is_workspace?(assembly_instance)
        assembly_instance.id_handle().create_object(:model_name => :assembly_workspace)
      else
        if opts[:only_workspace]
          raise ::DTK::ErrorUsage.new("The command can ony be applied to a workspace")
        end
        assembly_instance
      end
    end

    def ret_assembly_instance_object(id_param=nil)
      id_param ||= :assembly_id
      assembly_id = ret_request_param_id(id_param,::DTK::Assembly::Instance)
      id_handle(assembly_id,:component).create_object(:model_name => :assembly_instance)
    end
    def ret_assembly_template_object(id_param=nil)
      id_param ||= :assembly_id
      assembly_id = ret_request_param_id(id_param,::DTK::Assembly::Template)
      id_handle(assembly_id,:component).create_object(:model_name => :assembly_template)
    end

    def ret_assembly_params_id_and_subtype()
      subtype = (ret_request_params(:subtype)||:instance).to_sym
      assembly_id = ret_request_param_id(:assembly_id,subtype == :instance ? ::DTK::Assembly::Instance : ::DTK::Assembly::Template)
      [assembly_id,subtype]
    end

    def ret_assembly_subtype()
      (ret_request_params(:subtype)||:instance).to_sym
    end

    def ret_port_object(param,assembly_idh,conn_type)
      extra_context = {:assembly_idh => assembly_idh,:connection_type => conn_type}
      create_obj(param,::DTK::Port,extra_context)
    end

    def ret_component_id(param,context={})
      ret_request_param_id(param,::DTK::Component,context)
    end
    def ret_component_id?(param,context={})
      if ret_request_params(param)
        ret_component_id(param,context)
      end
    end
    def ret_component_id_handle(param,context={})
      id = ret_component_id(param,context)
      id_handle(id,:component)
    end

    def ret_node_id_handle(node_name_param,assembly)
      ret_request_param_id_handle(node_name_param,::DTK::Node,assembly.id())
    end

    #
    # Pass param name containing with comma seperated names or ids. Param name should
    # resolve to command seperated node id/names (String)
    #
    # Returns: Returns array of node id handles
    #
    def ret_node_id_handles(node_name_param, assembly)
      # get nodes list (command seperated) from request
      target_nodes_str = ret_request_params(node_name_param)
      return [] unless target_nodes_str
      # if node names exist, split them and remove extra spaces
      target_nodes = target_nodes_str.split(',').collect do |node_name| 
        ret_id_handle_from_value(node_name.strip, ::DTK::Node, assembly.id())
      end

      target_nodes
    end

    #assuming that service link is identified by either
    #:service_link_id or
    #:service_type and :input_component_id or
    #:dependency_type, :input_component_id, and :output_component_id
    def ret_port_link(assembly=nil)
      assembly ||= ret_assembly_instance_object()
      if ret_request_params(:service_link_id)
        create_obj(:service_link_id,::DTK::PortLink,:assembly_idh => assembly.id_handle())
      else
        filter =  {:input_component_id => ret_component_id(:input_component_id, :assembly_id => assembly.id())}
        if service_type = (ret_request_params(:dependency_name)||ret_request_params(:service_type))
          filter.merge!(:service_type => service_type)
        end
        if ret_request_params(:output_component_id)
          filter.merge!(:output_component_id => ret_component_id(:output_component_id, :assembly_id => assembly.id()))
        end
        assembly.get_matching_port_link(filter)
      end
    end

    #returns [assembly_template_name,service_module_name]; if cannot find one or both or these nil is returned in the associated element
    def get_template_and_service_names_params(assembly)
      assembly_template_name,service_module_name = ret_request_params(:assembly_template_name,:service_module_name)
      #either they both should be null or neither; however using 'or', rather than 'and' for robustness
      if assembly_template_name.nil? or service_module_name.nil?
        if parent_template = assembly.get_parent()
          assembly_template_name = parent_template[:display_name]
          if service_module = parent_template.get_service_module()
            service_module_name = service_module[:display_name]
          end
        end
      end
      [assembly_template_name,service_module_name]
    end

  end
end
