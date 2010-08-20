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
          {:external_attr_ref => {
              :type => 'text',
              :help => '',
            }},
          {:attribute_value => {
              :type => 'text',
              :help => '',
            }},
          {:description => {
              :type => 'text',
              :help => '',
            }},
      ]
}

