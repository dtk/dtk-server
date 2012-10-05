module Ramaze::Helper
  module AssemblyHelper
    def ret_assembly_params_object_and_subtype()
      assembly_id,subtype = ret_assembly_params_id_and_subtype()
      obj = id_handle(assembly_id,:component).create_object(:model_name => (subtype == :instance) ? :assembly_instance : :assembly_template) 
      [obj,subtype]
    end

    def ret_assembly_instance_object()
      assembly_id = ret_request_param_id(:assembly_id,::DTK::AssemblyInstance)
      id_handle(assembly_id,:component).create_object(:model_name => :assembly_instance)
    end

    def ret_assembly_params_id_and_subtype()
      subtype = (ret_request_params(:subtype)||:instance).to_sym
      assembly_id = ret_request_param_id(:assembly_id,subtype == :instance ? ::DTK::AssemblyInstance : ::DTK::AssemblyTemplate)
      [assembly_id,subtype]
    end

    def ret_assembly_subtype()
      (ret_request_params(:subtype)||:instance).to_sym
    end

    def ret_params_av_pairs()
      pattern,value,av_pairs_hash = ret_request_params(:pattern,:value,:av_pairs_hash)
      ret = Array.new
      if av_pairs_hash
        av_pairs_hash.each{|k,v|ret << {:pattern => k, :value => v}}
      elsif pattern and value
        ret = [{:pattern => pattern, :value => value}]
      else
        raise ::DTK::ErrorUsage.new("Missing parameters")
      end
      ret
    end
  end
end
