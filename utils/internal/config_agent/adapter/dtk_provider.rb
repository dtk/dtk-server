module DTK; class ConfigAgent; module Adapter
  class DtkProvider < ConfigAgent
#  require File.expand_path('puppet', File.dirname(__FILE__))
#  class DtkProvider < ConfigAgent::Adapter::Puppet
    def ret_msg_content(config_node,opts={})
      #cmps_with_attrs = components_with_attributes(config_node)
      # assembly_attrs = assembly_attributes(config_node)
      # TODO: stub
      ret = {
        :bash_command => 'ls /usr'
      }
      if assembly = opts[:assembly]
        ret.merge!(:service_id => assembly.id(), :service_name => assembly.get_field?(:display_name))
      end
      ret
    end

    def interpret_error(error_in_result,components)
pp [error_in_result,components]
        ret = error_in_result

        # if ends in 'on node NODEADDR' such as 'on node ip-10-28-77-115.ec2.internal'
        # strip it off because context is not needed and when summarize in node group can use simple test
        # to remove duplicate errors"
        
        if ret[:message] and ret[:message] =~ /(^.+) on node [^ ]+$/ 
          ret[:message] = $1
        end

        source = error_in_result["source"]
        # working under assumption that stage assignment same as order in components
        if source =~ Regexp.new("^/Stage\\[([0-9]+)\\]")
          index = ($1.to_i) -1
          if cmp_with_error = components[index]
            ret = error_in_result.inject({}) do |h,(k,v)|
              ["source","tags","time"].include?(k) ? h : h.merge(k => v)
            end
            if cmp_name = cmp_with_error[:display_name]
              ret.merge!("component" => cmp_name)
            end
          end
        end
        ret
      end


    def type()
      Type::Symbol.dtk_provider
    end

  end
end; end; end
