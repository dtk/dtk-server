#TODO: modify for that the abstract classes do what is below and the hash_render fn is what makes teh difference;
#this is because dont want to modify interface to front end
module XYZ
  module V1_0
    class ModuleMeta < ::XYZ::ModuleMeta
      def render_hash_form(opts={})
        ret = RenderHash.new
        ret["version"] = "1.0"
        self[:components].each_element(:skip_required_is_false => true) do |cmp|
          hash_key = cmp.hash_key
          ret[hash_key] = cmp.render_hash_form(opts)
        end
        ret
      end
    end
    class ComponentMeta < ::XYZ::ComponentMeta
      def render_hash_form(opts={})
        ret = RenderHash.new
        ret["display_name"] = required_value(:display_name)
        ret.set_unless_nil("label",value(:label))
        ret.set_unless_nil("description",value(:description))
        ret["external_ref"] = converted_external_ref()
        ret.set_unless_nil("ui",value(:ui))
        ret.set_unless_nil("basic_type",value(:basic_type))
        ret["component_type"] = required_value(:component_type)
        ret.set_unless_nil("dependency",converted_dependencies(opts))
        ret.set_unless_nil("attribute",converted_attributes(opts))
        ret.set_unless_nil("link_defs",converted_link_defs(opts))
        ret
      end

     private
      def converted_external_ref()
        ext_ref = required_value(:external_ref)
        ret = RenderHash.new
        ext_ref_key = 
          case ext_ref["type"]
            when "puppet_class" then "class_name"
            when "puppet_definition" then "definition_name"
            else raise Error.new("unexpected component type (#{ext_ref["type"]})")
          end
        #TODO: may need to append module name
        ret[ext_ref_key] = ext_ref["name"]
        ret["type"] = ext_ref["type"]
        (ext_ref.keys - ["name","type"]).each{|k|ret[k] = ext_ref[k]}
        ret
      end
      def converted_dependencies(opts)
        nil #TODO: stub
      end

      def converted_link_defs(opts)
        return nil unless lds = self[:link_defs]
        lds.map_element(:skip_required_is_false => true){|ld|ld.render_hash_form(opts)}
      end

      def converted_attributes(opts)
        attrs = self[:attributes]
        return nil if attrs.nil? or attrs.empty?
        ret = RenderHash.new
        attrs.each_element(:skip_required_is_false => true) do |attr|
          hash_key = attr.hash_key
          ret[hash_key] = attr.render_hash_form(opts)
        end
        ret
      end
    end

    class DependencyMeta < ::XYZ::DependencyMeta
      def render_hash_form(opts={})
        #TODO: stub
        ret = RenderHash.new
        ret
      end
    end

    class LinkDefMeta < ::XYZ::LinkDefMeta
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

    class LinkDefPossibleLinkMeta < ::XYZ::LinkDefPossibleLinkMeta
      def render_hash_form(opts={})
        ret = RenderHash.new
        ret["type"] = required_value(:type)
        attr_mappings = (self[:attribute_mappings]||[]).map{|am|am.render_hash_form(opts)}
        ret["attribute_mappings"] = attr_mappings unless attr_mappings.empty?
        ret
      end
    end

    class LinkDefAttributeMappingMeta  < ::XYZ::LinkDefAttributeMappingMeta
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

    class AttributeMeta < ::XYZ::AttributeMeta
      def render_hash_form(opts={})
        ret = RenderHash.new
        ret["display_name"] = required_value(:field_name)
        ret.set_unless_nil("description",value(:description))
        ret["data_type"] = required_value(:type)
        ret.set_unless_nil("value_asserted",value(:default_info))
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
end
