require 'active_support/core_ext/object/instance_variables'
class DTK::DocGenerator::Domain
  module ActiveSupportInstanceVariablesMixin
    def active_support_with_indifferent_access(obj)
      obj.with_indifferent_access
    end

    def active_support_instance_values(obj)
      obj.instance_values
    end
  end
end

