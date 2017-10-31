module DTKModule
  def self.execute(attributes)
    DTKModule.wrap(attributes, all_types: true) do |all_attributes|
      DTK::Response::Ok.new(success: true)
    end
  end
end

