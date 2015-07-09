module DTK; class Attribute
  class Pattern; class Type
    module CommonNodeComponentLevel
      def attribute_name
        attribute_stack()[:attribute][:display_name]
      end

      def attribute_id
        attribute_stack()[:attribute].id()
      end

      def component_instance
        attribute_stack()[:component]
      end

      def component_instances
        @attribute_stacks.map { |as| as[:component] }.compact
      end

      def node
        attribute_stack()[:node]
      end

      def attribute_idhs
        @attribute_stacks.map { |r| r[:attribute].id_handle() }
      end

      def node_group_member_attribute_idhs
        ret = []
        @attribute_stacks.each do |r|
          if r[:node].is_node_group?()
            ret += attribute_idhs_on_service_node_group(r[:attribute])
          end
        end
        ret
      end

      private

      def create_attributes(attr_parents)
        attribute_idhs = []
        attr_properties = attribute_properties().inject({}) { |h, (k, v)| h.merge(k.to_s => v) }
        field_def =
          { 'display_name' => pattern_attribute_name() }.merge(attr_properties)
        attr_parents.each do |attr_parent|
          attribute_idhs += Attribute.create_or_modify_field_def(attr_parent, field_def)
        end

        return attribute_idhs if attribute_idhs.empty?

        # TODO: can make more efficient by having create_or_modify_field_def return object with cols, rather than id_handles
        sp_hash = {
          cols: [:id, :group_id, :display_name, :description, :component_component_id, :data_type, :semantic_type, :required, :dynamic, :external_ref, :semantic_data_type],
          filter: [:oneof, :id, attribute_idhs.map(&:get_id)]
        }
        attr_mh = attribute_idhs.first.createMH()
        Model.get_objs(attr_mh, sp_hash)
      end

      def attribute_idhs_on_service_node_group(node_group_attribute)
        sp_hash = {
          cols: [:id, :display_name, :group_id],
          filter: [:eq, :ancestor_id, node_group_attribute.id()]
        }
        attr_mh = node_group_attribute.model_handle()
        Model.get_objs(attr_mh, sp_hash).map(&:id_handle)
      end

      def pattern_attribute_name
        first_name_in_fragment(pattern_attribute_fragment())
      end

      def first_name_in_fragment(fragment)
        fragment =~ NameInFragmentRegexp
        $1
      end
      NameInFragmentRegexp = /[^<]*<([^>]*)>/
    end
  end; end
end; end
