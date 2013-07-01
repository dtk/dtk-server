{
  :hidden_fields => [
    {
      :model => {
            :required => true,
            :type => 'hidden',
            :value => 'attribute',
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
      :attribute_current_start => {
        :required => false,
        :type => 'hidden',
        :value => '{%=attribute_current_start%}',
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
      :num_cols => 1,
        :display_labels => true,
          :fields => [
            {:display_name => {
              :type => 'text',
              :filter => 'starts_with',
              :rows => 1,
              :cols => 40,
            }},
        ],
      },
    ],
}

