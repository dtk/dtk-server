require File.expand_path("data_source_adapter", File.dirname(__FILE__))
module XYZ
  module DSAdapter
    class Ec2
      class Top < DataSourceAdapter
        class << self
          def connection()
            @@connection ||= CloudConnect::EC2.new
          end
        end
      end
    end
  end
end       
