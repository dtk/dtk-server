require_relative('../lib/ec2')
module DTKModule
  def self.execute(attributes)
    Aws::Stdlib.wrap(attributes) do |attributes| 
      attributes.debug_break_point?
      credentials_handle = attributes.aws_credentials_handle
      dynamic_attributes = Ec2::Node::Type::Group.start(credentials_handle, attributes.value(:name), attributes)
      DTK::Response::Ok.new(dynamic_attributes)
    end
  end
end

