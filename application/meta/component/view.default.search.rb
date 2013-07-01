{
  :hidden_fields => [
    {
      :model => {
            :required => true,
            :type => 'hidden',
            :value => 'component',
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
      :component_current_start => {
        :required => false,
        :type => 'hidden',
        :value => '{%=component_current_start%}',
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
            {:type => {
              :type => 'text',
              :filter => 'starts_with',
            }},
            {:basic_type => {
              :type => 'text',
              :filter => 'starts_with',
            }},
        ],
      },
    ],
}

