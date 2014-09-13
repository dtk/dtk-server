module DTK
  class ServiceSetting
    class AttributeSettings < Array
      r8_nested_require('attribute_settings','hash_form')
      r8_nested_require('attribute_settings','element')

      def initialize(settings_hash)
        super()
        self.class.each_element(settings_hash){|el| self << el}
      end

      def self.apply_using_settings_hash(assembly,settings_hash)
        attr_settings = new(settings_hash)
        pp attr_settings
        raise Error.new("Got here")
        attr_settings.apply_settings(assembly)
      end

      def self.each_element(settings_hash,attr_prefix=nil,&block)
        HashForm.each_element(settings_hash,attr_prefix,&block)
      end

      def apply_settings(assembly)
        av_pairs = map{|el|el.av_pair_form()}
        assembly.set_attributes(av_pairs)
      end
    end
  end
end
