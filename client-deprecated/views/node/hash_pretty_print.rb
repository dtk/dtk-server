module DTK::Client::ViewMeta
  HashPrettyPrint = {
    :top_type => :node,
    :defs => {
      :node_def =>
      [
       :display_name, 
       :type,
       :id, 
       :description, 
       {:external_ref => {:type => :external_ref}}
      ],
      :external_ref_def => 
      [
       :instance_id,
       :dns_name,
       :image_id
      ]
    }
  }
end

