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
          case type
            when :physical 
              "physical--#{name}" #TODO: can we change this to be just name
            when :base_node_link
              unless assembly_name = opts[:assembly] && opts[:assembly].get_field?(:display_name)
                raise Error.new("assembly option not given")
              end
              ret = "#{assembly_name}#{AssemblyDelim}#{name}"
              if index = opts[:index] 
                ret << "#{IndexDelim}#{index.to_s}"
              end
              ret
            else 
              raise Error.new("Unexpected type (#{type})")
          end
        end
        AssemblyDelim = '::'
        IndexDelim = ':'
      end
    end
  end
end; end
