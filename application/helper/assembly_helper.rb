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

  end
end
