require 'docile'
module DTK
  class Attribute
    class SemanticDatatype
      module SemanticDatatypeClassMixin
        def all_types
          @cache || {}
        end

        def Type(name, &block)
          el = ::Docile.dsl_eval(new(name), &block).build
          @cache ||= {}
          @cache.merge!(name.to_sym => el)
        end
      end

      module SemanticDatatypeMixin
        def basetype(datatype)
          datatype = datatype.to_sym
          unless DataTypes.include?(datatype)
            fail Error.new("Illegal datatype (#{datatype})")
          end
          @datatype = datatype
        end
        DataTypes = [:json, :string, :integer, :integer, :boolean]

        def parent(parent)
          @parent = parent.to_s
        end

        def validation(validation)
          @validation_proc =
            if validation.is_a?(Proc)
              validation
            elsif validation.is_a?(Regexp)
              lambda do |v|
                v.respond_to?(:to_s) &&
                (not v.is_a?(Array)) &&
                (not v.is_a?(Hash)) &&
                v.to_s =~ validation
              end
            else
              fail Error.new("Illegal validation argument (#{validation.inspect})")
            end
        end

        def internal_form(internal_form_proc)
          @internal_form_proc = internal_form_proc
        end

        def build
          unless @datatype
            fail Error.new('Datatype must be specified')
          end
          self
        end
      end
    end
  end
end
