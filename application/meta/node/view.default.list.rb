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
              :width => '20%',
              :help => '',
            }},
          {:display_name => {
              :type => 'text',
              :width => '20%',
              :help => '',
              :objLink => true,
              :objLinkView => 'display',
            }},
          {:operational_status => {
              :type => 'select',
              :width => '10%',
              :help => ''
            }},
          {:type => {
              :type => 'text',
              :width => '10%',
              :help => ''
            }},
          {:description => {
              :type => 'text',
              :help => '',
            }},
      ]
}

