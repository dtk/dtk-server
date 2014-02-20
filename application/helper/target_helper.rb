module Ramaze::Helper
  module TargetHelper

    def ret_target_subtype()
      (ret_request_params(:subtype)||:instance).to_sym
    end

    def ret_iaas_type(iaas_type_field=:iaas_type)
      iaas_type = (ret_non_null_request_params(iaas_type_field)).to_sym
      # check iaas type is valid
      supported_types = ::R8::Config[:ec2][:iaas_type][:supported]
      unless supported_types.include?(iaas_type.to_s.downcase)
        raise ::DTK::ErrorUsage.new("Invalid iaas type '#{iaas_type}', supported types (#{supported_types.join(', ')})") 
      end
      iaas_type
    end
  end
end
