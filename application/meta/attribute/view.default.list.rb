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
          {:port_type => {
              :type => 'text',
              :help => '',
            }},
          {:attribute_value => {
              :type => 'hash',
              :help => '',
            }},
      ]
}

