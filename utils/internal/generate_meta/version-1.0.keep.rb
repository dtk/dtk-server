#TODO: modify for that the abstract classes do what is below and the hash_render fn is what makes teh difference;
#this is because dont want to modify interface to front end
module XYZ
  module V1_0
    class ModuleMeta < ::XYZ::ModuleMeta
    end
    class ComponentMeta < ::XYZ::ComponentMeta
      def initialize(component_ps,context)
        super(context)
        processed_name = component_ps[:name]
        #if qualified name make sure matches module name
        if processed_name =~ /(^.+)::(.+$)/
          prefix = $1
          unqual_name = $2
          if processed_name =~ /::.+::/
            raise Error.new("unexpected class or definition name #{processed_name})")
          end
          unless prefix == module_name
            raise Error.new("prefix (#{prefix}) not equal to module name (#{module_name})")
          end 
          processed_name = "#{module_name}__#{unqual_name}"
        end

        set_hash_key(processed_name)
        self[:display_name] = t(processed_name) #TODO: might instead put in label
        self[:description] = unknown
        external_ref = SimpleOrderedHash.new()
        ext_ref_key = 
          case component_ps[:type]
            when "puppet_class" then :class_name
            when "puppet_definition" then :definition_name
            else raise Error.new("unexpected component type (#{component_ps[:type]})")
          end
        #TODO: need to append module name
        external_ref[ext_ref_key] = component_ps[:name]
        external_ref[:type] = component_ps[:type]
        self[:external_ref] = external_ref 
        attributes = (component_ps[:attributes]||[]).map{|attr_ps|create(:attribute,attr_ps)}
        self[:attributes] = attributes unless attributes.empty?
      end
    end
    class AttributeMeta < ::XYZ::AttributeMeta
      def initialize(attr_ps,context)
        super(context)
        name = attr_ps[:name]
        set_hash_key(name)
        self[:display_name] = t(name) 
        self[:description] = unknown
        if default = attr_ps[:default]
          self[:value_asserted] = t(default)
        end
      end
    end
  end
end
