{
  :tr_class => 'tr-dl',
  :hidden_fields => [
         {:id => {
            :required => true,
            :type => 'hidden',
          }}
      ],
      :field_list => [
          {:parent_name => {
              :type => 'text',
              :help => '',
            }},
          {:display_name => {
              :type => 'text',
              :help => '',
              :objLink => true,
              :objLinkView => 'display',
            }},
          {:change => {
              :type => 'hash',
              :help => '',
            }},
      ]
}

