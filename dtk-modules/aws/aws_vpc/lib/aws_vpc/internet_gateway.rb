module DTKModule
  class Aws::Vpc
    class InternetGateway < self
      require_relative('internet_gateway/operation')

      class OutputSettings <  OutputSettingsBase
        # Mapping from aws sdk call
        ATTRIBUTE_MAPPING = 
          [
           :internet_gateway_id,
           { vpc_ids: { fn: :map_vpc_ids }}
          ]

        def self.map_vpc_ids(aws_ig_result)
          aws_ig_result.attachments.map(&:vpc_id)
        end

      end
    end
  end
end

