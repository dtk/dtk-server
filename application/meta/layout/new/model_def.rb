{
  :schema=>:layout,
  :table=>:layout,
  :columns=>{
    :ancestor_id=> {
      :type=>:bigint,
      :foreign_key_rel_type=>:layout,
      :on_delete=>:set_null,
      :on_update=>:set_null
    },
    :model_id=> {
      :type=>:bigint
    },
    :model_parent=> {
      :type=>:text,
      :length=>50
    },
    :model_id=> {
      :type=>:bigint
    },
    :def=> {
      :type=>:json
    }
  },
  :one_to_many=>
  [
   :node,
   :component
  ],
  :virtual_columns=>{
  }
}
