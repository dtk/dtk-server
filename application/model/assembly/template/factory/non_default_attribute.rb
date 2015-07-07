module DTK; class Assembly; class Template 
  class Factory
    class NonDefaultAttribute < ::Hash
      attr_reader :is_title_attribute
      def initialize(attr,cmp)
        super()
        replace(Aux::hash_subset(attr,[:display_name,:description,:ref,:tags,:is_instance_value]))
        self[:attribute_value] = attr[:attribute_value] # virtual attributes do not work in Aux::hash_subset
        @is_title_attribute = ((not cmp[:only_one_per_node]) && attr.is_title_attribute?())
      end

      def self.isa?(attr,cmp)
        if isa_value_override?(attr) || !!base_tags?(attr)
          new(attr,cmp)
        end
      end

      def isa_value_override?
        self.class.isa_value_override?(self)
      end
      def self.isa_value_override?(attr)
        attr[:is_instance_value] && !attr[:attribute_value].nil?
      end

      def base_tags?
        self.class.base_tags?(self)
      end
      def self.base_tags?(attr)
        if attr[:tags] = HierarchicalTags.reify(attr[:tags])
          attr[:tags].base_tags?()
        end
      end

      def self.add_to_cmp_ref_hash!(cmp_ref_hash,factory,non_def_attrs,cmp_template_id)
        attr_names = non_def_attrs.map{|a|a[:display_name]}
        sp_hash = {
          cols: [:id,:display_name,:data_type,:semantic_data_type],
          filter: [:and,[:eq,:component_component_id,cmp_template_id],[:oneof,:display_name,attr_names]]
        }
        ndx_attrs = Model.get_objs(factory.model_handle(:attribute),sp_hash).inject({}) do |h,r|
          h.merge(r[:display_name] => r)
        end
        attr_override = cmp_ref_hash[:attribute_override] = {}
        non_def_attrs.each do |non_def_attr|
          if attribute_template = ndx_attrs[non_def_attr[:display_name]] 
            non_def_attr[:attribute_template_id] = attribute_template[:id]
            non_def_attr.merge!(Aux::hash_subset(attribute_template,[:data_type,:semantic_data_type]))
          else
            component_type = Component.display_name_print_form(cmp_ref_hash[:component_type])
            module_name = Component.module_name(cmp_ref_hash[:component_type])
            raise ErrorUsage.new("Attribute (#{non_def_attr[:display_name]}) does not exist in base component (#{component_type}); you may need to invoke push-module-updates #{module_name}")
          end
          attr_override[non_def_attr[:ref]] = non_def_attr
        end
      end
    end
  end
end; end; end
