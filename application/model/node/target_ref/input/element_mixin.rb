module DTK; class Node
  class TargetRef
    class Input 
      module ElementMixin
        attr_reader :type
        def ret_ref(name,opts={})
          case type
            when :physical
               "#{type}--#{name}"
            when :base_node_link 
            "#{type}--#{ret_display_name(name,opts)}"
            else 
              raise Error.new("Unexpected type (#{type})")
          end
        end
        def ret_display_name(name,opts={})
          opts_x = Hash.new
          if type == :base_node_link
            unless assembly_name = opts[:assembly] && opts[:assembly].get_field?(:display_name)
              raise Error.new("assembly option not given")
            end
            opts_x.merge!(:assembly_name => assembly_name)
            if index = opts[:index]
              opts_x.merge!(:index => index)
            end
            TargetRef.ret_display_name(type,name,opts_x)
          end
        end
      end
    end
  end
end; end
