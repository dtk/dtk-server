{
  :schema=>:file_asset,
  :table=>:file_asset,
  :columns=>{
    :name=> {
      :type=>:text,
      :length=>100
    },
    :type=> {
      :type=>:text,
      :length=>30
    },
    :content=> {
      :type=>:text
    }
  }
}
