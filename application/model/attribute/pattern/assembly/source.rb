module DTK; class Attribute; class Pattern 
  class Assembly
    #for attribute relation sources
    class Source < self
      def self.get_attribute_idh_and_fn(base_object_idh,source_attr_term)
        attr_term,fn = Simple.parse(source_attr_term) || 
                       AttributeInString.parse(source_attr_term)
        unless attr_term
          raise ErrorParse.new(source_attr_term)
        end
        attr_idhs = get_attribute_idhs(base_object_idh,attr_term)
        if attr_idhs.empty?
          raise ErrorUsage.new("The term (#{attr_term}) does not match an attribute")
        elsif attr_idhs.size > 1
          raise ErrorUsage.new("Source attribute term must match just one, not multiple attributes")
        end
        attr_idh = attr_idhs.first
        [attr_idh,fn]
      end
      
      class Simple
        def self.parse(source_term)
          if source_term =~ /^\$(.+$)/
            attr_term = $1
            [attr_term,nil]
          end
        end
      end

      class AttributeInString
        def self.parse(source_term)
          #TODO: change after fix stripping off of ""
          if source_term =~ /(^[^\$].*)\$\{([^\}]+)\}(.*)/
            str_part1 = $1
            attr_term = $2
            str_part2 = $3
            fn = {
              :function => {
                :name => :attribute_embded_in_text,
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
end; end; end
