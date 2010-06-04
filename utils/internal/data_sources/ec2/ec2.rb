module XYZ
  module DSAdapter
    class Ec2
      class Top < DataSourceAdapter
        class << self
          def get_objects__node()
            connection().servers_all()
          end
         private
          def connection()
            @@connection ||= CloudConnect::EC2.new
          end
        end
      end
    end
  end
end       
