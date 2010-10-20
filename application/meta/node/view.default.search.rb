{
  :hidden_fields => [
    {
      :model => {
            :required => true,
            :type => 'hidden',
            :value => 'node',
      },
    },
    {
      :action => {
        :required => true,
        :type => 'hidden',
        :value => 'list',
      },
    },
    {
      :node_current_start => {
        :required => false,
        :type => 'hidden',
        :value => '{%=node_current_start%}',
      },
    },
    {
      :query_params => {
        :required => true,
        :type => 'hidden',
        :value => '',
      },
    },
  ],
  :field_groups => [
    {
      :num_cols => 2,
        :display_labels => true,
          :fields => [
            {:display_name => {
              :type => 'text',
              :filter => 'starts_with',
              :rows => 1,
              :cols => 40,
            }},
            {:operational_status => {
              :type => 'multiselect',
              :filter => 'exact',
              :help => '',
            }},
            {:image_size => {
              :type => 'text',
              :filter => 'exact',
              :rows => 1,
              :cols => 40,
            }},
        ],
      },
    ],
}

