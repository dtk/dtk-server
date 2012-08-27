module DTK::Client::ViewMeta
  HashPrettyPrint = {
    :top_type => :state_change,
    :defs => {
      :state_change_def =>
      [
       :node_name, 
       :node_id,
       {:node_changes => {:type => :node_changes, :is_array => true}},
       {:component_changes => {:type => :cmp_changes, :is_array => true}}
      ],
      :node_changes_def => 
      [
       :name
      ],
      :cmp_changes_def => 
      [
       :component_name,
       :component_id,
       :changes
      ]
    }
  }
end

