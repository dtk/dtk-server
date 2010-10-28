{
  :tr_class => 'tr-dl',
  :hidden_fields => [
         {:id => {
            :required => true,
            :type => 'hidden',
          }}
      ],
      :field_list => [
          {:display_name => {
              :type => 'text',
              :help => '',
              :objLink => true,
              :objLinkView => 'display',
            }},
          {:id => {
              :type => 'integer',
              :help => '',
            }},
      ]
}

