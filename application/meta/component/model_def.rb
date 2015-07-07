
{
  impelements_owner: true,
  has_ancestor_fields: true,
  field_defs: {
    display_name: {
        type: :text,
        size: 50
    },
    parent_name: {
        type: :text
    },
    containing_datacenter: {
        type: :text
    },
    type: {
        type: :select,
        size: 15
    },
    basic_type: {
        type: :select,
        size: 15
    },
    has_pending_change: {
        type: :boolean,
    },
    version: {
        type: :text,
        size: 25,
    },
    uri: {
        type: :text,
    },
    ui: {
        type: :json,
    },
  },
  relationships: {
  }
}

