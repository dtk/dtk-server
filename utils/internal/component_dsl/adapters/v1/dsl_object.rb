#TODO: modify for that the abstract classes do what is below and the hash_render fn is what makes teh difference;
#this is because dont want to modify interface to front end
module DTK; class ComponentDSL; class V1
  Base = ComponentDSL::GenerateFromImpl::DSLObject
  class DSLObject
    class Module < Base::Module
     private
      def add_component!(ret,hash_key,content)
        ret[hash_key] = content
        ret
      end
    end
    class Component < Base::Component
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
      def display_name?()
        required_value(:display_name)
      end 
      def label?()
        value(:label)
      end
      def basic_type?()
        value(:basic_type)
      end
      def component_type?()
        required_value(:component_type)
      end
      def only_one_per_node?()
        value(:only_one_per_node)
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
     private
      def display_name?()
        required_value(:field_name)
      end
      def data_type_field()
        "data_type"
      end

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
