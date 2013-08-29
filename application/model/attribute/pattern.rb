module DTK; class Attribute
  class Pattern 
    r8_nested_require('pattern','type')
    r8_nested_require('pattern','assembly')
    r8_nested_require('pattern','node')

    CanonLeftDelim = '<'
    CanonRightDelim = '>'

    def self.get_attribute_idhs(base_object_idh,attr_term)
      create(attr_term,base_object_idh.create_object()).ret_or_create_attributes(base_object_idh)
    end

    def self.set_attributes(base_object,av_pairs,opts={})
      ret = Array.new
      attribute_rows = Array.new
      av_pairs.each do |av_pair|
        pattern = create(av_pair[:pattern],base_object,opts)
        #conditionally based on type ret_or_create_attributes may only ret and not create attributes
        attr_idhs = pattern.ret_or_create_attributes(base_object.id_handle(),Aux.hash_subset(opts,[:create]))
        unless attr_idhs.empty?
          attribute_rows += attr_idhs.map{|idh|{:id => idh.get_id(),:value_asserted => av_pair[:value]}}
        end
      end
      return ret if attribute_rows.empty?
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

      #TODO: clean up; modified because attr can be of type attribute or may have field :attribute]
      filter_proc = Proc.new do |attr|
        attr_id =
          if attr.kind_of?(Attribute) then attr[:id]
          elsif attr[:attribute] then attr[:attribute][:id]
          else
            raise Error.new("Unexpected argument attr (#{attr.inspect})")
          end
        attr_ids.include?(attr_id)
      end
      #filter_proc = proc{|attr|attr_ids.include?(attr[:id])}
      base_object.info_about(:attributes,Opts.new(:filter_proc => filter_proc))
    end

    class ErrorParse < ErrorUsage
      def initialize(pattern)
        super("Cannot parse #{pattern}")
      end
    end
    class ErrorNotImplementedYet < Error
      def initialize(pattern)
        super("not implemented yet: #{pattern}")
      end
    end
  end
end; end

