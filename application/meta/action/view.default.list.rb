{
  :tr_class => 'tr-dl',
  :hidden_fields => [
         {:id => {
            :required => true,
            :type => 'hidden',
          }}
      ],
      :field_list => [
         {:base_object => {
              :type => 'hash',
              :help => '',
            }},
          {:display_name => {
              :type => 'text',
              :help => '',
              :objLink => true,
              :objLinkView => 'display',
            }},
          {:old_value => {
              :type => 'hash',
              :help => '',
            }},
          {:new_value => {
              :type => 'hash',
              :help => '',
            }},
      ]
}

