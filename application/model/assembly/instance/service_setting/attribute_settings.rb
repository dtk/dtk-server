module DTK
  class ServiceSetting
    class AttributeSettings < Array
      r8_nested_require('attribute_settings', 'hash_form')
      r8_nested_require('attribute_settings', 'element')

      def initialize(settings_hash = {})
        super()
        unless settings_hash.empty?
          HashForm.each_element(settings_hash) { |el| self << el }
        end
      end

      def bind_parameters!(hash_params)
        # TODO: would be more efficient probably to apply these all at once raher than per element
        each { |el| el.bind_parameters!(hash_params) }
      end

      def self.apply_using_settings_hash(assembly, settings_hash)
        attr_settings = new(settings_hash)
        # get all existing attributes to find just the diffs
        existing_attr_settings = all_assemblies_attribute_settings(assembly)
        pruned_attr_settings = ret_just_diffs(attr_settings, existing_attr_settings)
        unless pruned_attr_settings.empty?
          pruned_attr_settings.apply_settings(assembly)
        end
      end

      def apply_settings(assembly)
        av_pairs = map(&:av_pair_form)
        opts_set = { partial_value: false, create: [:node_level, :assembly_level] }
        assembly.set_attributes(av_pairs, opts_set)
      end

      private

      def self.ret_just_diffs(attr_settings, existing_attr_settings)
        ret = new()
        ndx_attr_settings = existing_attr_settings.inject({}) do |h, el|
          h.merge(el.unique_index() => el)
        end
        attr_settings.each do |el|
          match = ndx_attr_settings[el.unique_index()]
          unless match && el.equal_value?(match)
            ret << el
          end
        end
        ret
      end

      def self.all_assemblies_attribute_settings(assembly, filter_proc = nil)
        new(HashForm.render(assembly.get_attributes_all_levels_struct(filter_proc)))
      end

    end
  end
end
