{
  :schema=>:port,
  :table=>:port,
  :columns=>{
    :type=>{
      :type=>:varchar,
      :size =>25
    }
  },
  :virtual_columns=>{},
  :many_to_one=>[:port,:node],
  :one_to_many=>[:port]
}
