{
  :tr_class => 'tr-dl',
  :hidden_fields => [
         {:id => {
            :required => true,
            :type => 'hidden',
          }}
      ],
      :field_list => [
         {:qualified_parent_name => {
              :type => 'text',
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

