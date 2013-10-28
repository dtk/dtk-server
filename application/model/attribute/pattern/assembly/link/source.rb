module DTK; class Attribute::Pattern
  class Assembly::Link
    #for attribute relation sources
    class Source < self
      def self.create_attr_pattern(base_object,source_attr_term)
        attr_term,fn = Simple.parse(source_attr_term) || 
                       VarEmbeddedInText.parse(source_attr_term)
        unless attr_term
          raise ErrorParse.new(source_attr_term)
        end
        attr_pattern = super(base_object,attr_term)
        new(attr_pattern,fn,attr_term)
      end
      
      attr_reader :attribute_pattern,:fn
      def attribute_idh()
        @attribute_pattern.attribute_idhs.first
      end
     private
      def initialize(attr_pattern,fn,attr_term)
        attr_idhs = attr_pattern.attribute_idhs
        if attr_idhs.empty?
          raise ErrorUsage.new("The term (#{attr_term}) does not match an attribute")
        elsif attr_idhs.size > 1
          raise ErrorUsage.new("Source attribute term must match just one, not multiple attributes")
        end
        @attribute_pattern = attr_pattern
        @fn = fn
      end

      class Simple
        def self.parse(source_term)
          if source_term =~ /^\$([a-z\-_0-9:\[\]\/]+$)/
            attr_term = $1
            [attr_term,nil]
          end
        end
      end

      class VarEmbeddedInText
        def self.parse(source_term)
          #TODO: change after fix stripping off of ""
          if source_term =~ /(^[^\$]*)\$\{([^\}]+)\}(.*)/
            str_part1 = $1
            attr_term = $2
            str_part2 = $3
            fn = {
              :function => {
                :name => :var_embedded_in_text,
                :constants => {
                  :text_parts => [str_part1,str_part2]
                }
              }
            }
            [attr_term,fn]
          end        
        end
        
      end
    end
  end
end; end

