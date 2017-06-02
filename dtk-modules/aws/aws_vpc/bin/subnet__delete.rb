require_relative('../lib/aws_vpc')
module DTKModule
  def self.execute(attributes)
    wrap(attributes) do |attributes| # TODO: until attributes are of type DTKModule::DTK::Attributes
      attributes.debug_break_point?
      credentials_handle = attributes.value?(:credentials_handle)
      dynamic_attributes = Aws::Vpc::Subnet.delete(credentials_handle, attributes.value(:name), attributes)
      DTK::Response::Ok.new(dynamic_attributes)
    end
  end
end

