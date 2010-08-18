{
      :action => 'index.php',
      :hidden_fields => [
        {
          :obj => {
            :required => true,
            :type => 'hidden',
            :value => 'component',
          },
        },
        {
          :action => {
            :required => true,
            :type => 'hidden',
            :value => 'save',
          },
        },
        {
          :id => {
            :required => true,
            :type => 'hidden',
          },
        },
      ],
      :field_groups => [
        {
          :num_cols => 1,
          :display_labels => true,
          :fields => [
            {:display_name => {
             :type => 'text',
             :help => '',
             :obj_link => true,
             :obj_link_view => 'display',
       :rows => 1,
             :cols => 20,
            }},
            {:external_type => {
              :type => 'text',
              :help => '',
        :rows => 1,
              :cols => 20,
            }},
=begin
            {:attributes => {
              :type => 'text',
              :help => '',
        :rows => 10,
              :cols => 60,
            }},
            {:service_attributes => {
              :type => 'text',
              :help => '',
        :rows => 10,
              :cols => 60,
            }},
=end
            {:description => {
              :type => 'text',
              :help => '',
        :rows => 1,
              :cols => 20,
            }},
        ],
      },
    ]
}

