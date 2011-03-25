{
  :schema=>:attribute,
  :table=>:link,
  :columns=>{
    :input_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:attribute,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :output_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:attribute,
      :on_delete=>:cascade,
      :on_update=>:cascade
    },
    :type=>{:type=>:varchar, :size=>25, :default => "external"}, # "internal" | "external" | "member"
    :hidden=>{:type=>:boolean, :default => false},
    :function=>{:type=>:json, :default => "eq"},
    :index_map=>{:type=>:json},
    :assembly_id=>{
      :type=>:bigint,
      :foreign_key_rel_type=>:component, #TODO: may instead just determine by seeing attributes contained and what is linked
      :on_delete=>:set_null,
      :on_update=>:set_null
    },
    :function_index=>{:type=>:json}, #TODO: deprecate; subsumed by :index_map
    :label=>{:type=>:text, :default => "1"} #TODO: deprecate; subsumed by :index_map
  },
  :many_to_one=>[:library, :datacenter, :component, :node]
}
