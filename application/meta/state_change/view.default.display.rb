{
      :action => '',
      :hidden_fields => [
        {
          :model => {
            :required => true,
            :type => 'hidden',
            :value => 'state_change',
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
            {:old_value => {
             :type => 'hash',
             :help => '',
            }},
            {:new_value => {
             :type => 'hash',
             :help => '',
            }},
        ],
      },
    ],
}

