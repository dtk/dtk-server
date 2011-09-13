module XYZ
  module LinkDefParseSerializedForm
    def parse_serialized_form_local(link_defs,config_agent_type,remote_link_defs)
      link_defs.inject({}) do |h,link_def|
        link_def_type = link_def["type"]
        ref = "local_#{link_def_type}"
        has_external_internal = Hash.new
        possible_link = parse_possible_links_local(link_def["possible_links"],link_def_type,config_agent_type,remote_link_defs,has_external_internal)
        el = {
          :display_name => ref,
          :local_or_remote => "local",
          :link_type => link_def_type,
          :link_def_link => possible_link
        }.merge(has_external_internal)
        el.merge!(:required => link_def["required"]) if link_def.has_key?("required")
        h.merge(ref => el)
      end
    end
   private
    def add_remote_link_def?(remote_link_defs,config_agent_type,remote_component_type,link_def_type,possible_link_type)
      pointer = remote_link_defs[remote_component_type] ||= Hash.new
      ref = "remote_#{link_def_type}"
      pointer[ref] ||= {
        :display_name => ref,
        :config_agent_type => config_agent_type,
        :local_or_remote => "remote",
        :link_type => link_def_type,
      }
      pointer[ref][:has_internal_link] = true if %w{internal internal_external}.include?(possible_link_type)
      pointer[ref][:has_external_link] = true if %w{external internal_external}.include?(possible_link_type)
    end

    def parse_possible_links_local(possible_links,link_def_type,config_agent_type,remote_link_defs,has_external_internal)
      position = 0
      possible_links.inject({}) do |h,possible_link|
        remote_component_type = possible_link.keys.first
        possible_link_info = possible_link.values.first
        possible_link_type = possible_link_info["type"]

        add_remote_link_def?(remote_link_defs,config_agent_type,remote_component_type,link_def_type,possible_link_type)

        has_external_internal[:has_internal_link] = true if %w{internal internal_external}.include?(possible_link_type)
        has_external_internal[:has_external_link] = true if %w{external internal_external}.include?(possible_link_type)

        position += 1
        ref = remote_component_type
        el = {
          :display_name => ref,
          :remote_component_type => remote_component_type,
          :position => position,
          :content => parse_possible_link_content(possible_link_info),
          :type => possible_link_type
        }
        h.merge(ref => el)
      end
    end

    def parse_possible_link_content(possible_link)
      ret = Hash.new
      events = possible_link["events"]||[]
      events.each do |evs|
        parsed_evs = parse_possible_link_on_create_events(evs)
        unless parsed_evs.empty?
          on_create_evs = (ret[:events] ||= Hash.new)[:on_create] ||= Array.new
          on_create_evs += parsed_evs
        end
      end
      attribute_mappings = possible_link["attribute_mappings"]||[]
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
    def parse_possible_link_on_create_events(events)
      trigger = events.first
      case trigger
       when "on_create_link" then parse_events(events[1])
       else
        Log.error("unexpected event trigger: #{trigger}")
        Array.new
      end
    end 

    def parse_events(events)
      ret = Array.new
      events.each do |ev|
        ev_type = ev.keys.first
        ev_content = ev.values.first
        case ev_type
         when "extend_component" 
          parsed_ev = parse_event_extend_component(ev_content)
          ret << parsed_ev if parsed_ev
         else
          Log.error("unexpected event type: #{ev_type}")
        end
      end
      ret
    end

    def parse_event_extend_component(ev_content)
      remote_or_local = ev_content[:node] || :remote
      ret = {
        :event_type => "extend_component",
        :node => remote_or_local,
        :extension_type => ev_content["extension_type"],
      }
      ret.merge!(:alias => ev_content["alias"]) if ev_content.has_key?("alias")
      ret
    end

    #returns node_name, component_name, attribute_name, path; where component_name xor node_name is null depending on whether it is a node or component attribute
    def parse_attribute_term(term_x)
      ret = Hash.new
      term = term_x.to_s.gsub(/^:/,"")
      ret[:term_index] = term
      split = term.split(SplitPat)

      if split[0] =~ NodeTermRE
        ret[:type] = "node_attribute"
        ret[:node_name] = $1
      elsif split[0] =~ ComponentTermRE
        ret[:type] = "component_attribute"
        ret[:component_type] = $1
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
