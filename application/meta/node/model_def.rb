#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
        default: 'instance'
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
        size: [8, 3]
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