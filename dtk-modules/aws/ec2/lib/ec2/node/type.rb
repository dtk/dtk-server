module DTKModule
  class Ec2::Node
    module Type
      require_relative('type/single')
      require_relative('type/group')
    end
  end
end
