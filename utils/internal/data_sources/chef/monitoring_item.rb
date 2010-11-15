module XYZ
  module DSNormalizer
    class Chef
      class MonitoringItem < Top
        definitions do
          target[:display_name] = source[:ref]
        end

         class << self
           def relative_distinguished_name(source)
             source[:ref]
           end
        end
      end
    end
  end
end

