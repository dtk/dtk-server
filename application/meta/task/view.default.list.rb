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
      ]
}

