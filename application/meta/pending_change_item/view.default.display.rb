{
      :action => '',
      :hidden_fields => [
        {
          :model => {
            :required => true,
            :type => 'hidden',
            :value => 'pending_change_item',
          },
        },
        {
          :id => {
            :required => true,
            :type => 'hidden',
          },
        },
      ],
      :field_groups => [
        {
          :num_cols => 1,
          :display_labels => true,
          :fields => [
            {:parent_name => {
             :type => 'text',
             :help => '',
             :rows => 1,
             :cols => 40,
            }},
            {:display_name => {
             :type => 'text',
             :help => '',
             :obj_link => true,
             :obj_link_view => 'display',
             :rows => 1,
             :cols => 40,
            }},
            {:change => {
             :type => 'hash',
             :help => '',
             :rows => 1,
             :cols => 40,
            }},
        ],
      },
    ],
}

