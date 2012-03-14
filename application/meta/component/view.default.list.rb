{
  :tr_class => 'tr-dl',
  :hidden_fields => 
  [
   {:id => {
       :required => true,
       :type => 'hidden',
     }}
  ],
  :field_list => 
  [
   {:display_name => {
       :type => 'text',
       :width => '20%',
       :help => '',
       :objLink => true,
       :objLinkView => 'display',
     }},
   {:parent_name => {
       :type => 'text',
       :width => '20%',
       :help => '',
     }},
   {:type => {
       :type => 'select',
       :width => '7%',
       :help => '',
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
      {:route => 'component/details/{%=component[:id]%}',:label=>'details'}
      ]
    }},
    {:instance => {
      :type => 'actions_basic',
      :help => '',
      :action_seperator => '&nbsp;|&nbsp;',
      :action_list => [
      {:route => 'component/instance_edit_test/{%=component[:id]%}',:label=>'instance'}
      ]
    }},
=begin
   {:created_at => {
       :type => 'text',
     }},
=end
  ]
}
