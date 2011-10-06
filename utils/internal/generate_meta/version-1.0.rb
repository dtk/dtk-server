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
      end
    end
    class AttributeMeta < ::XYZ::AttributeMeta
    end
  end
end
