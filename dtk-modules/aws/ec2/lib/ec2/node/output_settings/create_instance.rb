module DTKModule
  class Ec2::Node
    class OutputSettings
      class CreateInstance
        EXPLICIT_ATTRIBUTES = [:image_id, :os_type, :instance_type]
        DERIVE_ATTRIBUTES   = [:vpc_images, :image, :size]

        def initialize(attributes)
          @attributes = attributes
        end
        private :initialize

        # modifies attributes if needed and returns output settings with the create instance dynamic attributes
        def self.set_attributes!(attributes)
          new(attributes).set_attributes!
        end
        def set_attributes!
          if has_all_attributes?(EXPLICIT_ATTRIBUTES)
            OutputSettings.new.merge(EXPLICIT_ATTRIBUTES.inject({}) { |h, name| h.merge(name => attributes.value(name)) })
          elsif has_all_attributes?(DERIVE_ATTRIBUTES)
            compute_and_set_explicit_attributes!
          else
            fail DTK::Error::Usage, "Either the attributes (#{EXPLICIT_ATTRIBUTES.join(', ')}) must be given or the attributes (#{DERIVE_ATTRIBUTES.join(', ')})"
          end
        end

        attr_reader :attributes

        private

        def has_all_attributes?(names)
          ! names.find { |name| attributes.value?(name).nil? }
        end

        def compute_and_set_explicit_attributes!
          vpc_images = attributes.value(:vpc_images)
          image      = attributes.value(:image).to_sym
          size       = attributes.value(:size).to_sym

          unless image_info = vpc_images[image]
            fail DTK::Error::Usage, "The image '#{image}' is illegal. It must be form set: #{vpc_images.keys.join(', ')}"
          end

          unless instance_type = image_info[:sizes][size]
            fail DTK::Error::Usage, "The size '#{size}' is illegal. It must be form set: #{image_info[:sizes].keys.join(', ')}"
          end
          explicit_values = {
            image_id: image_info[:ami],
            os_type: image_info[:os_type],
            instance_type: instance_type
          }
          explicit_values.each_pair { |name, value| attributes.set_value!(name, value) }
          OutputSettings.new.merge(explicit_values)
        end

      end
    end
  end
end
