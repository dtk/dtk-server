module XYZ
  module LinkDefParseSerializedForm
    def parse_serialized_form(link_defs)
      link_defs.inject({}) do |h,link_def|
        ref = link_def["type"] 
        el = {
          :display_name => name,
          :possible_link => parse_possible_links(link_def["possible_links"])
        }
        el.merge!(:required => link_def["required"]) if link_def.has_key?("required")
        h.merge(ref => el)
      end
    end
   private
    def parse_possible_links(possible_links)
      position = 0
      possible_links.inject({}) do |h,possible_link|
        position += 1
        ref = possible_link.keys.first
        possible_link_info = possible_link.va;lues.first
        el = {
          :position => position,
          :content => parse_possible_link_content(possible_link_info),
          :type => "external" #TODO: hard wired for first test
        }
        h.merge(ref => el)
      end
    end

    def parse_possible_link_content(possible_link)
      ret = Hash.new
      events = ret["events"]||[]
      unless events.empty?
        ret[:events] = events.map{|ev|parse_possible_link_event(ev)}
      end
      attribute_mappings = ret["attribute_mappings"]||[]
      unless attribute_mappings.empty?
        ret[:attribute_mappings] = attribute_mappings.map{|am|parse_possible_link_attribute_mapping(am)}
      end
      ret
    end

    def parse_possible_link_attribute_mapping(mapping)
      {
        :output => parse_attribute_term(mapping.keys.first),
        :input => parse_attribute_term(mapping.values.first)
      }
    end
    def parse_possible_link_event(events)
      ret = Array.new
      return ret if events.empty?
      #TODO: stub
      ret
    end

    #returns node_name, component_name, attribute_name, path; where component_name xor node_name is null depending on whether it is a node or component attribute
    def parse_attribute_term(term_x)
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
