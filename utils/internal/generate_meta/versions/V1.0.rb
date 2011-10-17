#TODO: modify for that the abstract classes do what is below and the hash_render fn is what makes teh difference;
#this is because dont want to modify interface to front end
module XYZ
  module V1_0
    class ModuleMeta < ::XYZ::ModuleMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret["version"] = "1.0"
        self[:components].each do |cmp|
          unless cmp.do_not_include?()
            hash_key = cmp.hash_key_dup?
            ret[hash_key] = cmp.render_hash_form(opts)
          end
        end
        ret
      end
    end
    class ComponentMeta < ::XYZ::ComponentMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret["display_name"] = required_value(:display_name)
        ret.set?("label",value(:label))
        ret.set?("description",value(:description))
        ret["external_ref"] = converted_external_ref()
        ret.set?("ui",value(:ui))
        ret.set?("basic_type",value(:basic_type))
        ret["component_type"] = required_value(:component_type)
        ret.set?("dependency",converted_dependencies(opts))
        ret.set?("link_defs",converted_link_defs(opts))
        ret.set?("attribute",converted_attributes(opts))
        ret
      end

      private
      def converted_external_ref()
        ext_ref = required_value(:external_ref)
        ret = SimpleOrderedHash.new
        ext_ref_key = 
          case ext_ref[:type]
            when "puppet_class" then "class_name"
            when "puppet_definition" then "definition_name"
            else raise Error.new("unexpected component type (#{ext_ref[:type]})")
          end
        #TODO: may need to append module name
        ret[ext_ref_key] = ext_ref[:name].dup?
        ret["type"] = ext_ref[:type].dup?
        (ext_ref.keys - [:name,:type]).each{|k|ret[k] = ext_ref[k].dup?}
        ret
      end

      def converted_dependencies(opts)
        nil #TODO: stub
      end

      def converted_link_defs(opts)
        return nil unless lds = self[:link_defs]
        lds.reject{|ld|ld.do_not_include?}.map{|ld|ld.render_hash_form(opts)}
      end

      def converted_attributes(opts)
        attrs = self[:attributes]
        return nil if attrs.nil? or attrs.empty?
        ret = SimpleOrderedHash.new
        attrs.each do |attr|
          unless attr.do_not_include?()
            hash_key = attr.hash_key_dup?
            ret[hash_key] = attr.render_hash_form(opts)
          end
        end
        ret
      end
    end

    class DependencyMeta < ::XYZ::DependencyMeta
      def render_hash_form(opts={})
        #TODO: stub
        ret = SimpleOrderedHash.new
        ret
      end
    end

    class LinkDefMeta < ::XYZ::LinkDefMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret["type"] = required_value(:type)
        ret.set?("required",value(:required))
        self[:possible_links].each do |link|
          unless link.do_not_include?()
            hash_key = link.hash_key_dup?
            ret[hash_key] = link.render_hash_form(opts)
          end
        end
        ret
      end
    end

    class LinkDefPossibleLinkMeta < ::XYZ::LinkDefPossibleLinkMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret["type"] = required_value(:type)
        attr_mappings = (self[:attribute_mappings]||[]).map{|am|converted_attribute_mapping(am)}
        ret["attribute_mappings"] = attr_mappings unless attr_mappings.empty?
        ret
      end
     private
      def converted_attribute_mapping(attr_mapping)
        in_cmp = attr_mapping[:input][:component]
        in_attr = attr_mapping[:input][:attribute]
        out_cmp = attr_mapping[:output][:component]
        out_attr = attr_mapping[:output][:attribute]
        SimpleOrderedHash.new(attr_ref(out_cmp,out_attr) => attr_ref(in_cmp,in_attr))
      end
      def attr_ref(cmp,attr)
        ":#{cmp}.#{attr}"
      end
    end

    class AttributeMeta < ::XYZ::AttributeMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret["display_name"] = required_value(:field_name)
        ret.set?("description",value(:description))
        ret["data_type"] = required_value(:type)
        ret.set?("value_asserted",value(:default_info))
        ret["external_ref"] = converted_external_ref()
        ret
      end
     private
      def converted_external_ref()
        ext_ref = required_value(:external_ref)
        ret = SimpleOrderedHash.new
        ret["type"] = "#{config_agent_type}_attribute"
        ret["path"] = "node[#{module_name}][#{ext_ref[:name]}]"
        (ext_ref.keys - [:name]).each{|k|ret[k] = ext_ref[k].dup?}
        ret
      end
    end
  end
end
