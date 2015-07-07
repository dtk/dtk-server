{
  schema: :link_def,
  table: :link_def,
  columns: {
    local_or_remote: {type: :varchar, size: 10},
    link_type: {type: :varchar, size: 50},
    required: {type: :boolean},
    dangling: {type: :boolean, default: false},
    has_external_link: {type: :boolean},
    has_internal_link: {type: :boolean}
  },
  virtual_columns: {
    link_def_link: {
      type: :json,
      hidden: true,
      remote_dependencies:       [{
         model_name: :link_def_link,
         convert: true,
         join_type: :left_outer,
         join_cond: {link_def_id: :link_def__id},
         cols: LinkDef::Link.common_columns()
       }]
    }
  },
  many_to_one: [:component],
  one_to_many: [:link_def_link]
}

