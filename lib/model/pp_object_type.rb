module DTK
  class Model
    #format below can be
    # :s - singular (default)
    # :p - plural
    # :pos - plural or singular    
    module PPObjectTypeMixin
      def pp_object_type(format=nil)
        self.class.pp_object_type(format)
      end
    end
    module PPObjectTypeClassMixin
      def pp_object_type(format=nil)
        PPObjectType.render(self,format)
      end
    end

    class PPObjectType < String
      def self.render(model_class,format=nil)
        format ||= :s
        print_form = SubclassProcessing.print_form(model_class) || model_class.to_s.split("::").last.gsub(/([a-z])([A-Z])/,'\1 \2').downcase
        string = case format
          when :s then print_form
          when :p then make_plural(print_form)
          when :pos then make_plural(print_form,:plural_or_singular => true)
          else raise Error.new("Unexpected format (#{format})")
        end
        new(string)
      end

      def cap()
        split(' ').map{|word|word.capitalize}.join(' ')
      end

    private
      def self.pp_object_type__make_plural(term,opts={})
        if term =~ /y$/
          opts[:plural_or_singular] ? "#{term[0...-1]}(ies)" : "#{term[0...-1]}ies"
        else
          opts[:plural_or_singular] ? "#{term}(s)" : "#{term}s"
        end
      end
    end
  end
end
