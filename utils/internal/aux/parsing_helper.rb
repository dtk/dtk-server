module DTK
  class Aux
    # assumption is that where this included could have a Variations module
    module ParsingingHelper
      module ClassMixin
        def matches?(object,constant)
          unless object.nil?
            variations = variations(constant)
            if object.kind_of?(Hash)
              hash_matches_key?(object,variations)
            elsif object.kind_of?(String) or object.kind_of?(Symbol)
               variations.include?(object.to_s)
            else
              raise Error.new("Unexpected object class (#{object.class})")
            end            
          end
        end

        def its_legal_values(constant)
          single_or_set = variations(constant,:string_only=>true)
          if single_or_set.kind_of?(Array)
            "its legal values are: #{single_or_set.join(',')}"
          else
            "its legal value is: #{single_or_set}"
          end
        end
       private            
        def variations(constant,opts={})
          # use of self:: and self. are important beacuse want to evalute wrt to module that pulls this in
          begin
            variations = self::Variations.const_get(constant.to_s)
            string_variations = variations.map{|v|v.to_s} 
            opts[:string_only] ? string_variations : string_variations + variations.map{|v|v.to_sym}
           rescue
            # if Variations not defined
            # self:: is important beacuse want to evalute wrt to module that pulss this in
            term = self.const_get(constant.to_s)
            opts[:string_only] ? [term.to_s] : [term.to_s,term.to_sym]
          end
        end

        def hash_matches_key?(hash,variations)
          if match_key = variations.find{|key|hash.has_key?(key)}
            hash[match_key]
          end
        end

      end
    end
  end
end
