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
      :id => {
        :required => true,
        :type => 'hidden',
        :value => '{%=saved_search_id%}',
#        :value => '{%=saved_search[:id]%}',
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
      :saved_search => {
        :required => true,
        :type => 'hidden',
        :value => '',
      },
    },
  ],
  :field_groups => [
    {
      :num_cols => 3,
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

