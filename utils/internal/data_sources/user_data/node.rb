module XYZ
  module DSNormalizer
    class UserData
      class Node < Top
        definitions do
          target[:display_name] = fn(:display_name, source)
          %w(tag disk_size ui).each do |key|
            target[key.to_sym] = source[key]
          end
        end
         class << self
            def unique_keys(source)
              [source['qualified_ref']]
            end

           def relative_distinguished_name(source)
             source['ref']
           end

           def display_name(source)
             source['display_name'] || source['ref']
           end
         end
      end
    end
  end
end
