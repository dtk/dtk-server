{
  :tr_class => 'tr-dl',
  :hidden_fields => [
         {:id => {
            :required => true,
            :type => 'hidden',
          }}
      ],
      :field_list => [
          {:external_attr_ref => {
              :type => 'text',
              :help => '',
              :objLink => true,
              :objLinkView => 'display',
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

