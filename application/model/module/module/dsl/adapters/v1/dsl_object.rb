# TODO: modify for that the abstract classes do what is below and the hash_render fn is what makes teh difference;
# this is because dont want to modify interface to front end
module DTK; class ModuleDSL; class V1
  Base = ModuleDSL::GenerateFromImpl::DSLObject
  class DSLObject
    class Module < Base::Module
      private

      def add_component!(ret, hash_key, content)
        ret[hash_key] = content
        ret
      end
    end
    class Component < Base::Component
      def render_hash_form(opts = {})
        ret = RenderHash.new
        ret.set_unless_nil('display_name', display_name?())
        ret.set_unless_nil('label', label?())
        ret.set_unless_nil('description', value(:description))
        ret['external_ref'] = converted_external_ref()
        ret.set_unless_nil('ui', value(:ui))
        ret.set_unless_nil('basic_type', basic_type?())
        ret.set_unless_nil('type', type?())
        ret.set_unless_nil('component_type', component_type?())
        ret.set_unless_nil('only_one_per_node', only_one_per_node?())
        ret.set_unless_nil('dependency', converted_dependencies(opts))
        ret.set_unless_nil('attribute', converted_attributes(opts))
        ret.set_unless_nil('link_defs', converted_link_defs(opts))
        ret
      end

      private

      def converted_external_ref
        ext_ref = required_value(:external_ref)
        ret = RenderHash.new
        ext_ref_key =
          case ext_ref['type']
          when 'puppet_class' then 'class_name'
          when 'puppet_definition' then 'definition_name'
          else raise Error.new("unexpected component type (#{ext_ref['type']})")
          end
        # TODO: may need to append module name
        ret[ext_ref_key] = ext_ref['name']
        ret['type'] = ext_ref['type']
        (ext_ref.keys - ['name', 'type']).each { |k| ret[k] = ext_ref[k] }
        ret
      end

      def display_name?
        required_value(:display_name)
      end

      def label?
        value(:label)
      end

      def basic_type?
        value(:basic_type)
      end

      def component_type?
        required_value(:component_type)
      end

      def only_one_per_node?
        value(:only_one_per_node)
      end
    end

    class Dependency < Base::Dependency
      def render_hash_form(_opts = {})
        # TODO: stub
        ret = RenderHash.new
        ret
      end
    end

    class LinkDef < Base::LinkDef
      def render_hash_form(opts = {})
        ret = RenderHash.new
        ret['type'] = required_value(:type)
        ret.set_unless_nil('required', value(:required))
        self[:possible_links].each_element(skip_required_is_false: true) do |link|
          (ret['possible_links'] ||= []) << { link.hash_key => link.render_hash_form(opts) }
        end
        ret
      end
    end

    class LinkDefPossibleLink < Base::LinkDefPossibleLink
      def render_hash_form(opts = {})
        ret = RenderHash.new
        ret['type'] = required_value(:type)
        attr_mappings = (self[:attribute_mappings] || []).map { |am| am.render_hash_form(opts) }
        ret['attribute_mappings'] = attr_mappings unless attr_mappings.empty?
        ret
      end
    end

    class LinkDefAttributeMapping < Base::LinkDefAttributeMapping
      def render_hash_form(_opts = {})
        input = self[:input]
        output = self[:output]
        in_cmp = index(input, :component)
        in_attr = index(input, :attribute)
        out_cmp = index(output, :component)
        out_attr = index(output, :attribute)
        RenderHash.new(attr_ref(out_cmp, out_attr) => attr_ref(in_cmp, in_attr))
      end

      private

      def attr_ref(cmp, attr)
        ":#{cmp}.#{attr}"
      end
    end

    class Attribute < Base::Attribute
      def render_hash_form(_opts = {})
        ret = RenderHash.new
        ret.set_unless_nil('display_name', display_name?())
        ret.set_unless_nil('description', value(:description))
        ret['data_type'] = required_value(:type)
        ret.set_unless_nil('value_asserted', value(:default_info))
        ret['required'] = true if value(:required)
        ret.set_unless_nil('dynamic', value(:dynamic))
        ret.set_unless_nil('external_ref', converted_external_ref())
        ret
      end

      private

      def display_name?
        required_value(:field_name)
      end

      def converted_external_ref
        ext_ref = required_value(:external_ref)
        ret = RenderHash.new
        ret['type'] = ext_ref['type']
        ret['path'] = "node[#{module_name}][#{ext_ref['name']}]"
        (ext_ref.keys - ['name', 'type']).each { |k| ret[k] = ext_ref[k] }
        ret
      end
    end
  end
end; end; end
