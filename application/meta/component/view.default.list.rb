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
              :width => '20%',
              :help => '',
              :objLink => true,
              :objLinkView => 'display',
            }},
          {:description => {
              :type => 'text',
              :help => '',
            }},
      ]
}

