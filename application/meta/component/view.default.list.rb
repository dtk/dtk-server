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
   {:type => {
       :type => 'select',
       :width => '20%',
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
=begin
   {:created_at => {
       :type => 'text',
     }},
=end
  ]
}
