module DTK; class Clone
  class IncrementalUpdate
    class Attribute < self
      FieldsToNotCopy = [:id,:ref,:display_name,:group_id,:component_component_id,:value_derived,:value_asserted,:is_port,:port_type_asserted]
      # instance_template_links has type InstanceTemplate::Links
      def self.modify_instances(model_handle,instance_template_links)
        parent_id_col = model_handle.parent_id_field_name()
        update_rows = instance_template_links.map do |l|
          Aux.hash_subset(l.template,l.template.keys-FieldsToNotCopy).merge(:id => l.instance.id)
        end
        Model.update_from_rows(model_handle,update_rows)
      end

     private
      # TODO: put in equality test so that does not need to do the modify equal objects
      def equal_so_dont_modify?(instance,template)
        false
      end
      
      def update_opts()
        # TODO: can refine to allow deletes if instance has nil value and not in any attribute link
        # can do this by passing in a charachterstic fn
        #{:donot_allow_deletes => true}
        super
      end
      
      def get_ndx_objects(component_idhs)
        ret = Hash.new
        ::DTK::Component.get_attributes(component_idhs,:cols_plus => [:component_component_id,:ref]).each do |r|
          (ret[r[:component_component_id]] ||= Array.new) << r
        end
        ret
      end

    end
  end
end; end
