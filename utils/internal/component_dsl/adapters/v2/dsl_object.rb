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
          else Log.error("not traeted yet config_agent type (#{config_agent_type})")
        end
      end

      def render_cmp_ref(cmp_ref)
        strip_module_name(cmp_ref)
      end

      def strip_module_name(cmp_ref)
        cmp_ref.gsub(Regexp.new("^#{module_name()}__"),"")
      end
    end

    class Component < Base::Component
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
        ret["display_name"] = required_value(:field_name)
        ret.set_unless_nil("description",value(:description))
        ret["data_type"] = required_value(:type)
        ret.set_unless_nil("value_asserted",value(:default_info))
        ret.set_unless_nil("required",value(:required))
        ret.set_unless_nil("dynamic",value(:dynamic))
        ret["external_ref"] = converted_external_ref()
        ret
      end
     private
      def converted_external_ref()
        ext_ref = required_value(:external_ref)
        ret = RenderHash.new
        ret["type"] = ext_ref["type"]
        ret["path"] = "node[#{module_name}][#{ext_ref["name"]}]"
        (ext_ref.keys - ["name","type"]).each{|k|ret[k] = ext_ref[k]}
        ret
      end
    end
  end
end; end; end
