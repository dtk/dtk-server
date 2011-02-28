{
  :schema=>:dependency,
  :table=>:dependency,
  :columns=>{
    :type=>{:type=>:varchar, :size=>20},
    :search_pattern=>{:type=>:json},
  },
  :many_to_one=>[:component,:attribute]
}
