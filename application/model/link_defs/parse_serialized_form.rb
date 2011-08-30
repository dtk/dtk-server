module XYZ
  module LinkDefParseSerializedForm
    def self.parse_attribute_mapping(mapping)
      {
        :output => parse_attribute_term(mapping.keys.first),
        :input => parse_attribute_term(mapping.values.first)
      }
    end
    def self.parse_events(events)
      ret = Array.new
      return ret if events.empty?
      #TODO: stub
      ret
    end
    private
    #returns node_name, component_name, attribute_name, path; where component_name xor node_name is null depending on whether it is a node or component attribute
    def self.parse_attribute_term(term_x)
      ret = Hash.new
      term = term_x.to_s.gsub(/^:/,"")
      split = term.split(SplitTerm)

      if split[0] =~ NodeTermRE
        ret[:node_name] = $1
      elseif split[0] =~ ComponentTermRE
        ret[:component_name] = $1
      else
        raise Error.new("unexpected form")
      end

      unless split.size > 1
        raise Error.new("unexpected form")
      end
      if split[1] =~ AttributeTermRE
        ret[:attribute_name] = $1
      else
        raise Error.new("unexpected form")
      end
      
      if split.size > 2
        ret[:path] = split[2,split.size-2]
      end
      ret
    end      

    SimpleTokenPat = 'a-zA-Z0-9_-'
    AnyTokenPat = SimpleTokenPat + '_\[\]:'
    SplitPat = '.'

    NodeTermRE = Regexp.new("^(local|remote)_node$") 
    ComponentTermRE = Regexp.new("^([#{SimpleTokenPat}]+$)") 
    AttributeTermRE = Regexp.new("^([#{SimpleTokenPat}]+$)") 
  end
end
