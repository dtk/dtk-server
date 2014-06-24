{
  :schema=>:monitoring,
  :table=>:item,
  :columns=>{
    :service_name=>{
      :type=>:varchar,
      :size =>50
    },
    :condition_name=>{
      :type=>:varchar,
      :size =>50
    },
    :condition_description=>{
      :type=>:varchar
    },
    :enabled=>{
      :type=>:boolean
    },
    :params=>{
      :type=>:json
    },
    # TODO: this may be be broken out as children objects
    :attributes_to_monitor=>{
      :type=>:json
    }
  },
  :many_to_one=>[:component,:node]
}
