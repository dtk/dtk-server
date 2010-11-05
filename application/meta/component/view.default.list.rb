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
   {:created_at => {
       :type => 'text',
     }},
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
  ]
}
