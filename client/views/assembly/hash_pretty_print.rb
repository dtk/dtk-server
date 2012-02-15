module R8::Client::ViewMeta
  HashPrettyPrint = {
    :top_type => :assembly,
    :defs => {
      :assembly_def =>
      [
       :display_name,
       :id,
       {:nodes  => {:type => :node, :is_array => true}}
      ],
      :node_def => [:node_name, :node_id, :components]
    }
  }
end

