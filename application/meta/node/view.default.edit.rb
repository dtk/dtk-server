{
      :action => '',
      :hidden_fields => [
        {
          :model => {
            :required => true,
            :type => 'hidden',
            :value => 'node',
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
             :rows => 1,
             :cols => 40,
            }},
            {:type => {
             :type => 'text',
             :help => '',
            }},
           {:ec2_security_groups => {
             :type => 'hash',
             :help => '',
            }},
            {:image_size => {
             :type => 'text',
             :help => '',
             :rows => 1,
             :cols => 40,
            }},
            {:description => {
              :type => 'text',
              :help => '',
              :rows => 1,
              :cols => 40,
            }},
        ],
      },
    ],
}

