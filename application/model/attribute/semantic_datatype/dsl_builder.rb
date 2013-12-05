require 'docile'
module DTK
  class Attribute 
    class SemanticDatatype
      module SemanticDatatypeClassMixin
        def all_types()
          @cache||Hash.new
        end
        def Type(name,&block)
          el = ::Docile.dsl_eval(new(name),&block).build
          @cache ||= Hash.new
          @cache.merge!(name.to_sym => el)
        end
      end

      module SemanticDatatypeMixin
        def datatype(datatype)
          datatype = datatype.to_sym
          unless DataTypes.include?(datatype)
            raise Error.new("Illegal datatype (#{datatype})")
          end
          @datatype = datatype
        end
        DataTypes = [:json,:string,:integer,:integer,:boolean]

        def parent(parent)
          @parent = parent.to_s
        end
        def validation(validation)
          @validation =
            if validation.kind_of?(Proc)
              validation
            elsif validation.kind_of?(Regexp)
              lambda{|v|v.to_s =~ validation}
            else
              raise Error.new("Illegal validation argument (#{validation.inspect})")
            end
        end
        def build()
          unless @datatype
            raise Error.new("Datatype must be specified")
          end
          self
        end
      end
    end
  end
end
