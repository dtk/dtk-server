module XYZ
  module DSAdapter
    class Ec2
      class Top < DataSourceAdapter
        class << self
          def get(object_path)
            if object_path =~ %r{^/servers/all$}
              connection().servers_all()
            end
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
