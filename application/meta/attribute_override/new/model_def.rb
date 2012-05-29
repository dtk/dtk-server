{
  :schema=>:attribute,
  :table=>:override,
  :columns=>{
    :attribute_value => {:type => :json}
  },
  :many_to_one => [:component_ref]
}
