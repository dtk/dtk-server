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

}

