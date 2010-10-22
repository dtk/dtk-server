{
      :action => '',
      :hidden_fields => [
        {
          :model => {
            :required => true,
            :type => 'hidden',
            :value => 'action',
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
            {:search => {
             :type => 'hash',
             :help => '',
             :rows => 5,
             :cols => 40,
            }},
            {:search_result => {
             :type => 'hash',
             :help => '',
             :rows => 5,
             :cols => 40,
            }},
        ],
      },
    ],
}

