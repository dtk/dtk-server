# TODO: might  move baseto aws_stdlib
module DTKModule
  class Aws::Vpc
    # For making aws api calls this is a filter
    class Filter
      def initialize(name, values)
        @name    = name
        @values = (values.kind_of?(::Array) ? values : [values])
      end
      
      def hash
        { name: @name, values: @values }
      end
      
      class Vpc < self
        def initialize(vpc_id)
          super('vpc-id', vpc_id)
        end
      end

      class Subnet < self
        def initialize(subnet_id)
          super('subnet-id', subnet_id)
        end
      end
      
    end
  end
end


