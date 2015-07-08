
{
  has_ancestor_field: true,
  implements_owner: true,
  field_defs: {
    display_name: {
        type: :text,
        size: 50
    },
    tag: {
        type: 'text',
        size: 25
    },
    type: {
        type: 'select',
        size: 25,
        default: "instance"
    },
    os: {
        type: 'text',
        size: 25
    },
    is_deployed: {
        type: 'boolean'
    },
    architecture: {
        type: 'text',
        size: 10
    },
    image_size: {
        type: 'numeric',
        size: [8,3]
    },
    operational_status: {
        type: 'select',
        size: 50
    },
    disk_size: {
        type: 'numeric'
    },
    ui: {
        type: 'json',
        omit: %w(list display edit filter order_by)
    },
    has_pending_change: {
        type: :boolean
    },
    parent_name: {
        type: 'text',
        no_column: true
    },
    parent_id: {
        type: 'related',
        omit: ['all']
    },
    ordered_component_ids: {
        type: 'text'
    }
  },
  relationships: {

  }
}
