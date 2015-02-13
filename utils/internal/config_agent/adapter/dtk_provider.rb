module DTK; class ConfigAgent; module Adapter
  class DtkProvider < ConfigAgent
    def ret_msg_content(config_node,opts={})
      #cmps_with_attrs = components_with_attributes(config_node)
      # assembly_attrs = assembly_attributes(config_node)
      # TODO: stub
pp [:config_node,config_node]
      ret = {
        :bash_command => 'ls /usr'
      }
      if assembly = opts[:assembly]
        ret.merge!(:service_id => assembly.id(), :service_name => assembly.get_field?(:display_name))
      end
      ret
    end

    #TODO: stub
    def interpret_error(error_in_result,components)
pp [error_in_result,components]
      ret = error_in_result
      ret
    end


    def type()
      Type::Symbol.dtk_provider
    end

  end
end; end; end
