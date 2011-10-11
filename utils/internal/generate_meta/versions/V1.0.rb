#TODO: modify for that the abstract classes do what is below and the hash_render fn is what makes teh difference;
#this is because dont want to modify interface to front end
module XYZ
  module V1_0
    class ModuleMeta < ::XYZ::ModuleMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret[:version] = "1.0"
        self[:components].each do |cmp|
          unless (not value(:include).nil?) and not value(:include)
            hash_key = cmp.required_value(:hash_key)
            ret[hash_key] = cmp.render_hash_form(opts)
          end
        end
        ret
      end
    end
    class ComponentMeta < ::XYZ::ComponentMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret[:display_name] = required_value(:display_name)
        ret.set?(:description,value(:description))
        ext_ref = required_value(:external_ref)
        ret[:external_ref] = convert_external_ref(ext_ref)
        ret
      end
      private
      def convert_external_ref(ext_ref)
        ret = SimpleOrderedHash.new
        ext_ref_key = 
          case ext_ref[:type]
            when "puppet_class" then :class_name
            when "puppet_definition" then :definition_name
            else raise Error.new("unexpected component type (#{ext_ref[:type]})")
          end
        #TODO: may need to append module name
        ret[ext_ref_key] = ext_ref[:name]
        ret[:type] = ext_ref[:type]
        ret
      end
    end
    class DependencyMeta < ::XYZ::DependencyMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret
      end
    end
    class AttributeMeta < ::XYZ::AttributeMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret
      end
    end
  end
end
