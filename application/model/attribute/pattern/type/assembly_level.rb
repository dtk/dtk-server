module DTK; class Attribute
  class Pattern; class Type
    class AssemblyLevel < self
      def type()
        :assembly_level
      end

      def attribute_idhs()
        @attributes_stack.map{|attr|attr[:attribute].id_handle()}
      end
      
      def component_instance()
        nil
      end
      
      def set_parent_and_attributes!(assembly_idh,opts={})
        attributes = ret_matching_attributes(:component,[assembly_idh],pattern)
        #if does not exist then create the attribute if create option is true
        #if exists and create flag exsists we just assign it new value
        if attributes.empty? and opts[:create]
          af = ret_filter(pattern,:attribute)
          #attribute must have simple form 
          unless af.kind_of?(Array) and af.size == 3 and af[0..1] == [:eq,:display_name]
            raise Error.new("cannot create new attribute from attribute pattern #{pattern}")
          end
          attr_properties = opts[:attribute_properties]||Hash.new
          unless attr_properties.empty?
            if attr_properties[:dynamic]
              raise ErrorUsage.new("Illegal to include teh :dynamic option on an assembly level attribute")
            elsif attr_properties[:required]
              raise Error.new("The option :required not yet supported on assembly leveal attributes")
            end
            set_attribute_properties!(attr_properties)
          end
          @created = true
          field_def = {"display_name" => af[2]}
          attribute_idhs = assembly_idh.create_object().create_or_modify_field_def(field_def)
          attributes = attribute_idhs.map do |idh|
            attr = idh.create_object()
            attr.update_object!(:display_name)
            attr
          end
        end
        assembly = assembly_idh.create_object()
        assembly.update_object!(:display_name)
        @attributes_stack = attributes.map do |attr| 
          {
            :assembly => assembly,
            :attribute => attr
          }
        end
        self
      end
    end
  end; end
end; end
