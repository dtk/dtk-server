module DTK; class ComponentDSL; class V2
  Base = ComponentDSL::GenerateFromImpl::DSLObject
  class DSLObject
    class Module < Base::Module
     private
      def module_name?()
        module_name()
      end

      def module_type?()
        config_agent_type = config_agent_type()
        case config_agent_type
          when :puppet then "puppet_module"
          else Log.error("not treated yet config_agent type (#{config_agent_type})")
        end
      end

      def add_component!(ret,hash_key,content)
        (ret["components"] ||= Hash.new)[hash_key] = content
        ret
      end

      def render_cmp_ref(cmp_ref)
        strip_module_name(cmp_ref).gsub(/::/,'_')
      end

      def strip_module_name(cmp_ref)
        cmp_ref.gsub(Regexp.new("^#{module_name()}__"),"")
      end
    end

    class Component < Base::Component
      def render_hash_form(opts={})
        ret = RenderHash.new
        ret.set_unless_nil("display_name",display_name?())
        ret.set_unless_nil("label",label?())
        ret.set_unless_nil("description",value(:description))
        ret["external_ref"] = converted_external_ref()
        ret.set_unless_nil("ui",value(:ui))
        ret.set_unless_nil("basic_type",basic_type?())
        ret.set_unless_nil("type",type?())
        ret.set_unless_nil("component_type",component_type?())
        ret.set_unless_nil("attributes",converted_attributes(opts))
        ret.set_unless_nil("link_defs",converted_link_defs(opts))
        ret
      end

     private
      def converted_external_ref()
        ext_ref = required_value(:external_ref)
        ret = RenderHash.new
        #ext_ref["type"] will be "puppet_class" or "puppet_definition" for pupppet config agent
        ret[ext_ref["type"]] = ext_ref["name"]
        (ext_ref.keys - ["name","type"]).each{|k|ret[k] = ext_ref[k]}
        ret
      end

      def type?()
        basic_type = value(:basic_type)
        #'service' is default
        basic_type == "service" ? nil : basic_type
      end

    end

    class Dependency < Base::Dependency
      def render_hash_form(opts={})
        #TODO: stub
        ret = RenderHash.new
        ret
      end
    end

    class LinkDef < Base::LinkDef
      def render_hash_form(opts={})
        ret = RenderHash.new
        ret["type"] = required_value(:type)
        ret.set_unless_nil("required",value(:required))
        self[:possible_links].each_element(:skip_required_is_false => true) do |link|
          (ret["possible_links"] ||= Array.new) << {link.hash_key => link.render_hash_form(opts)}
        end
        ret
      end
    end

    class LinkDefPossibleLink < Base::LinkDefPossibleLink
      def render_hash_form(opts={})
        ret = RenderHash.new
        ret["type"] = required_value(:type)
        attr_mappings = (self[:attribute_mappings]||[]).map{|am|am.render_hash_form(opts)}
        ret["attribute_mappings"] = attr_mappings unless attr_mappings.empty?
        ret
      end
    end

    class LinkDefAttributeMapping  < Base::LinkDefAttributeMapping
      def render_hash_form(opts={})
        input = self[:input]
        output = self[:output]
        in_cmp = index(input,:component)
        in_attr = index(input,:attribute)
        out_cmp = index(output,:component)
        out_attr = index(output,:attribute)
        RenderHash.new(attr_ref(out_cmp,out_attr) => attr_ref(in_cmp,in_attr))
      end
      private
      def attr_ref(cmp,attr)
        ":#{cmp}.#{attr}"
      end
    end

    class Attribute < Base::Attribute
      def render_hash_form(opts={})
        ret = RenderHash.new
        ret.set_unless_nil("description",value(:description))
        ret["type"] = required_value(:type)
        #better heuristic is to not set dtk default to parsed implementation default
        #ret.set_unless_nil("default",value(:default_info))
        ret["required"] = true if value(:required)
        ret.set_unless_nil("dynamic",value(:dynamic))
        ret.set_unless_nil("external_ref",converted_external_ref())
        ret
      end

     private
      def converted_external_ref()
        ret = RenderHash.new
        ext_ref = required_value(:external_ref)
        attr_name = ext_ref["name"]
        unless attr_name == value(:id)
          ret[ext_ref["type"]] = attr_name
        end
        #do not need its value; just fact that default_variable
        (ext_ref.keys - ["name","type","default_variable"]).each{|k|ret[k] = ext_ref[k]}
        if ext_ref["default_variable"]
          ret["default_variable"] = true
        end
        ret.empty? ? nil : ret
      end
    end
  end
end; end; end
