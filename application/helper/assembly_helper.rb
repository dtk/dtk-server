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

    #returns [component_template_idh, component_title] where component_title could be nil
    def ret_component_template_idh_and_title(param)
      component_template_idh = ret_request_param_id_handle(param,::DTK::Component::Template)
      component_title = ::DTK::ComponentTitle.parse_title?(ret_non_null_request_params(param))
      [component_template_idh,component_title]
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

    #assuming that service link is identified by either
    #:service_link_id, or
    #:service_type and :input_component_id
    def ret_port_link(assembly=nil)
      assembly ||= ret_assembly_instance_object()
      if ret_request_params(:service_link_id)
        create_obj(:service_link_id,::DTK::PortLink,:assembly_idh => assembly.id_handle())
      else
        service_type = ret_non_null_request_params(:service_type)
        input_component_id = ret_component_id(:input_component_id, :assembly_id => assembly.id())
        filter = {:service_type => service_type, :input_component_id => input_component_id}
        assembly.get_matching_port_link(filter)
      end
    end

  end
end
