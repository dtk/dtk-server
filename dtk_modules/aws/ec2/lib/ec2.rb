module DTKModule
  require_relative('../../aws_stdlib/lib/aws_stdlib') # TODO: replace with a 'dtk_module_require' method supplied by ruby provider
  module Ec2
    require_relative('ec2/node')
  end
end    
