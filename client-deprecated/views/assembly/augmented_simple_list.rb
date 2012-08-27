module DTK::Client::ViewMeta
  AugmentedSimpleList = {
    :attribute_def => {
      :keys => [:attribute_name,:value,:override],
      :fn => lambda() do |attribute_name,value,override|
        augment = (override ? " [override]" : "")
        "#{attribute_name} = #{value}#{augment}"
      end
    }
  }
end

