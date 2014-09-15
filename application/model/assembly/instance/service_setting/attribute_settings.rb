module DTK
  class ServiceSetting
    class AttributeSettings < Array
      r8_nested_require('attribute_settings','hash_form')
      r8_nested_require('attribute_settings','element')

      def initialize(settings_hash={})
        super()
        unless settings_hash.empty?
          self.class.each_element(settings_hash){|el| self << el}
        end
      end

      def self.apply_using_settings_hash(assembly,settings_hash)
        attr_settings = new(settings_hash)
        # get all existing attributes to find just the diffs
        existing_attr_settings = all_assemblies_attribute_settings(assembly) 
        pruned_attr_settings = attr_settings.ret_just_diffs(existing_attr_settings)
        unless pruned_attr_settings.empty?
          pruned_attr_settings.apply_settings(assembly)
        end
      end

      def self.each_element(settings_hash,attr_prefix=nil,&block)
        HashForm.each_element(settings_hash,attr_prefix,&block)
      end

      def apply_settings(assembly)
        av_pairs = map{|el|el.av_pair_form()}
        assembly.set_attributes(av_pairs)
      end

      def ret_just_diffs(existing_attr_settings)
        ret = self.class.new()
        ndx_attr_settings = existing_attr_settings.inject(Hash.new) do |h,el|
          h.merge(el.unique_index() => el)
        end
        each do |el|
          match = ndx_attr_settings[el.unique_index()]
          unless match and el.equal_value?(match)
            ret << el
          end
        end
        ret
      end

     private
      def self.all_assemblies_attribute_settings(assembly,filter_proc=nil)
        new(HashForm.render(assembly.get_attributes_all_levels_struct(filter_proc)))
      end
    end
  end
end
