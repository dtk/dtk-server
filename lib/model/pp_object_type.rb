module DTK
  class Model
    class PPObjectType < String
      # format below can be
      # :s - singular (default)
      # :p - plural
      # :pos - plural or singular
      module Mixin
        def pp_object_type(format=nil)
          self.class.pp_object_type(format)
        end
      end
      module ClassMixin
        def pp_object_type(format=nil)
          PPObjectType.render(self,format)
        end

        def object_type_string
          to_s.split("::").last.gsub(/([a-z])([A-Z])/,'\1 \2').downcase
        end
      end

      def self.render(model_class,format_or_cardinality=nil)
        print_form = SubclassProcessing.print_form(model_class) || model_class.object_type_string()
        string =
          if format_or_cardinality.is_a?(Fixnum)
            cardinality = format_or_cardinality
            if cardinality > 1
              make_plural(print_form)
            else
              print_form
            end
          else
            format = format_or_cardinality||:s
            case format
              when :s then print_form
              when :p then make_plural(print_form)
              when :pos then make_plural(print_form,plural_or_singular: true)
              else raise Error.new("Unexpected format (#{format})")
            end
          end
        new(string)
      end

      def cap
        split(' ').map{|word|word.capitalize}.join(' ')
      end

      private

      def self.make_plural(term,opts={})
        if term =~ /y$/
          opts[:plural_or_singular] ? "#{term[0...-1]}(ies)" : "#{term[0...-1]}ies"
        else
          opts[:plural_or_singular] ? "#{term}(s)" : "#{term}s"
        end
      end
    end
  end
end
