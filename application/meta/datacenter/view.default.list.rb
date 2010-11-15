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
          {:description => {
              :type => 'text',
              :help => '',
            }},
          {:actions => {
              :type => 'actions_basic',
              :help => '',
              :action_seperator => '&nbsp;|&nbsp;',
              :action_list => [
                {:route => 'workspace/list_items_2/{%=datacenter[:id]%}',:label=>'load'}
              ]
            }},
      ]
}

