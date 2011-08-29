{
  :schema=>:link_def,
  :table=>:attribute_mapping,
  :columns=>{
    :output_attribute_id => {
      :type=>:bigint,
      :foreign_key_rel_type=>:attribute,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :output_path => {:type => :varchar, :size => 25},
    :output_contant => {:type => :varchar}, #if this is non null then meaning is to set input to contant value (and output_attribute_id and output_path will be null
    :input_attribute_id => {
      :type=>:bigint,
      :foreign_key_rel_type=>:attribute,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :input_path => {:type => :varchar, :size => 25},
  },
  :many_to_one=>[:link_def_possible_link]
}

