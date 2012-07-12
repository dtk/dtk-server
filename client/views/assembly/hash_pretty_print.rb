module DTK::Client::ViewMeta
  HashPrettyPrint = {
    :top_type => :assembly,
    :defs => {
      :assembly_def =>
      [
       :display_name,
       :id,
       :execution_status,
       {:nodes  => {:type => :node, :is_array => true}}
      ],
      :node_def => 
      [
       :node_name, 
       :node_id, 
       :os_type,
       {:external_ref => {:type => :external_ref, :only_explicit_cols => true}},
       {:components => {:type => :component, :is_array => true}}
      ],
      :external_ref_def =>
      [
       :image_id,
       :size,
       :dns_name,
       :private_dns_name
      ],
      :component_def => 
      [
       :component_name,
       {:attributes => {:type => :attribute, :is_array => true}}
      ],
      :attribute_def => [:attribute_name,:value,:override]
    }
  }
end

