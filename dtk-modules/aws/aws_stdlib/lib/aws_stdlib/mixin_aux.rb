require 'net/http'
module DTKModule
  module Aws::Stdlib
    module Mixin
      module Aux
        def self.filter(name, *values)
          { filters: [{ name: name, values: values }] }
        end

        METADATA_BASE = 'http://169.254.169.254/latest/meta-data'
        def self.metadata(key)
          ::Net::HTTP.get(::URI.parse("#{METADATA_BASE}/#{key}"))
        end

      end
    end
  end
end


