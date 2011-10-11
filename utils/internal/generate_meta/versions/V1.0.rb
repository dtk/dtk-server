#TODO: modify for that the abstract classes do what is below and the hash_render fn is what makes teh difference;
#this is because dont want to modify interface to front end
module XYZ
  module V1_0
    class ModuleMeta < ::XYZ::ModuleMeta
      def render_hash_form(opts={})
        ret = SimpleOrderedHash.new
        ret[:version] = value(:version)
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
        ret
      end
    end
    class  DependencyMeta < ::XYZ::DependencyMeta
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
