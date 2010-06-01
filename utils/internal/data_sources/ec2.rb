require File.expand_path("top", File.dirname(__FILE__))
module XYZ
  module CloudProvider
    module Ec2
      class Top < CloudProvider::Top
        class << self
          def connection()
            @@connection ||= CloudConnect::EC2.new
          end
        end
      end
    end
  end
end       
