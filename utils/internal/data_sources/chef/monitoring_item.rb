module XYZ
  module DSNormalizer
    class Chef
      class MonitoringItem < Top
        definitions do
          target[:display_name] = source[:ref]
          %w(condition_name service_name condition_description enabled params attributes_to_monitor).each do |k|
            target[k.to_sym] = source[k.to_sym]
          end
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
