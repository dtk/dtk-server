module XYZ
  module DSNormalizer
    class Chef
      class MonitoringItem < Top
        definitions do
          target[:display_name] = source[]["name"]
        end

         class << self
           def unique_keys(source)
             source.keys.first
           end

           def relative_distinguished_name(source)
             source.keys.first
           end
        end
      end
    end
  end
end

