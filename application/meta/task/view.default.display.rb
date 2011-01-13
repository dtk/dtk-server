{
      :action => '',
      :hidden_fields => [
        {
          :model => {
            :required => true,
            :type => 'hidden',
            :value => 'task',
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
            {:display_name => {
             :type => 'text',
             :help => '',
             :obj_link => true,
             :obj_link_view => 'display',
             :rows => 1,
             :cols => 40,
            }},
            {:temporal_order => {
              :type => 'text',
              :help => '',
            }},
            {:executable_action_type => {
              :type => 'text',
              :help => '',
            }},
            {:executable_action => {
              :type => 'hash',
              :help => '',
            }}
        ],
      },
    ],
}

