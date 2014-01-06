module DTK; class Attribute
  class Pattern 

    r8_nested_require('pattern','type')
    r8_nested_require('pattern','assembly')
    r8_nested_require('pattern','node')

    module Term
      def self.canonical_form(type,term)
        "#{type}#{LDelim}#{term}#{RDelim}"
      end
      def self.extract_term?(canonical_form)
        $1 if canonical_form =~ FilterFragmentRegexp
      end
      LDelim = '<'
      RDelim = '>'
      FilterFragmentRegexp = Regexp.new("[a-z]\\#{LDelim}([^\\#{RDelim}]+)\\#{RDelim}")
    end

    def self.create_attr_pattern(base_object,attr_term,opts={})
      create(attr_term,base_object,opts).set_parent_and_attributes!(base_object.id_handle(),opts)
    end

    #returns attribute patterns
    def self.set_attributes(base_object,av_pairs,opts={})
      ret = Array.new
      attribute_rows = Array.new
      attr_properties = opts[:attribute_properties]||{}
      av_pairs.each do |av_pair|
        value = av_pair[:value]
        if semantic_data_type = attr_properties[:semantic_data_type]
          if value
            unless SemanticDatatype.is_valid?(semantic_data_type,value)
              raise ErrorUsage.new("The value (#{value.inspect}) is not of type (#{semantic_data_type})")
            end
          end
        end
        pattern = create_attr_pattern(base_object,av_pair[:pattern],opts)
        ret << pattern
        attr_idhs = pattern.attribute_idhs
        #TODO: modify; rather than checking checking datatype; convert attribute value, which might be in string form to right ruby data type
        #do not need to check value validity if opts[:create] (since checked already)
        unless opts[:create]
          attr_idhs.each do |attr_idh|
            unless pattern.valid_value?(value,attr_idh)
              raise ErrorUsage.new("The value (#{value.inspect}) is not of type (#{pattern.semantic_data_type(attr_idh)})")
            end
          end
        end
        unless attr_idhs.empty?
          attribute_rows += attr_idhs.map{|idh|{:id => idh.get_id(),:value_asserted => value}.merge(attr_properties)}
        end
      end

      if attribute_rows.empty?
        if opts[:create]
          raise ErrorUsage.new("Unable to create a new attribute")
        else
          raise ErrorUsage.new("The attribute specified does not match an existing attribute in the assembly")
        end
      end

      attr_ids = attribute_rows.map{|r|r[:id]}
      attr_mh = base_object.model_handle(:attribute)

      sp_hash = {
        :cols => [:id,:group_id,:display_name,:node_node_id,:component_component_id],
        :filter => [:oneof,:id,attribute_rows.map{|a|a[:id]}]
      }
      existing_attrs = Model.get_objs(attr_mh,sp_hash)
      ndx_new_vals = attribute_rows.inject(Hash.new){|h,r|h.merge(r[:id] => r[:value_asserted])}
      LegalValue.raise_usage_errors?(existing_attrs,ndx_new_vals)

      Attribute.update_and_propagate_attributes(attr_mh,attribute_rows)
      SpecialProcessing::Update.handle_special_processing_attributes(existing_attrs,ndx_new_vals)
      ret
    end

  end
end; end

