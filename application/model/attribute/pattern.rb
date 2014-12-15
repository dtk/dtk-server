module DTK; class Attribute
  class Pattern 

    r8_nested_require('pattern','type')
    r8_nested_require('pattern','assembly')
    r8_nested_require('pattern','node')
    r8_nested_require('pattern','term')

    def self.node_name()
      (pattern =~ NodeComponentRegexp ? $1 : raise_unexpected_pattern(pattern))
    end
    def self.component_fragment(pattern)
      (pattern =~ NodeComponentRegexp ? $2 : raise_unexpected_pattern(pattern))
    end
    def self.attribute_fragment(pattern)
      (pattern =~ AttrRegexp ? $1 : raise_unexpected_pattern(pattern))
    end
    Delim = "#{Term::EscpLDelim}[^#{Term::EscpRDelim}]*#{Term::EscpRDelim}"
    DelimWithSelect = "#{Term::EscpLDelim}([^#{Term::EscpRDelim}]*)#{Term::EscpRDelim}"

    NodeComponentRegexp = Regexp.new("^node#{DelimWithSelect}\/(component.+$)")
    AttrRegexp = Regexp.new("node[^\/]*\/component#{Delim}\/(attribute.+$)")

    def self.raise_unexpected_pattern(pattern)
      raise Error.new("Unexpected that pattern (#{pattern}) did not match")
    end
    private_class_method :raise_unexpected_pattern

    def self.create_attr_pattern(base_object,attr_term,opts={})
      create(attr_term,base_object,opts).set_parent_and_attributes!(base_object.id_handle(),opts)
    end

    # set_attributes can create or set attributes depending on options in opts
    # returns attribute patterns
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
        # if needed as indicated by opts, create_attr_pattern also creates attribute
        pattern = create_attr_pattern(base_object,av_pair[:pattern],opts)
        ret << pattern
        # attribute_idhs are base level attribute id_handles; in contrast to
        # node_group_member_attribute_idhs, which gives non null set if attribute is on a node and node is a service_node_group
        # purpose of finding node_group_member_attribute_idhs is when explicitly setting node group attribute want to set
        # all its members to same value; only checking for component level and not node level because 
        # node level attributes different for each node member
        attr_idhs = pattern.attribute_idhs
        ngm_attr_idhs = pattern.kind_of?(Type::ComponentLevel) ? pattern.node_group_member_attribute_idhs : []
        # TODO: modify; rather than checking datatype; convert attribute value, which might be in string form to right ruby data type
        # do not need to check value validity if opts[:create] (since checked already)
        unless opts[:create]
          attr_idhs.each do |attr_idh|
            unless pattern.valid_value?(value,attr_idh)
              raise ErrorUsage.new("The value (#{value.inspect}) is not of type (#{pattern.semantic_data_type(attr_idh)})")
            end
          end
        end

        all_attr_idhs = attr_idhs
        unless ngm_attr_idhs.empty?
          if opts[:create]
            raise ErrorUsage.new("Not supported creating attributes on a node group")
          end
          all_attr_idhs += ngm_attr_idhs
        end
        all_attr_idhs.each do |idh|
          attribute_rows << {:id => idh.get_id(),:value_asserted => value}.merge(attr_properties)
        end
      end

      # attribute_rows can have multiple rows if pattern decomposes into multiple attributes
      # it should have at least one row or there is an error
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
      existing_attrs = Model.get_objs(attr_mh,sp_hash,opts)
      ndx_new_vals = attribute_rows.inject(Hash.new){|h,r|h.merge(r[:id] => r[:value_asserted])}
      LegalValue.raise_usage_errors?(existing_attrs,ndx_new_vals)

      SpecialProcessing::Update.handle_special_processing_attributes(existing_attrs,ndx_new_vals)
      Attribute.update_and_propagate_attributes(attr_mh,attribute_rows,opts)
      ret
    end

  end
end; end

