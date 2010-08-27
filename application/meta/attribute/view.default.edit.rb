{
      :action => 'index.php',
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
             :obj_link => true,
             :obj_link_view => 'display',
             :rows => 1,
             :cols => 40,
            }},
            {:external_attr_ref => {
             :type => 'text',
             :help => '',
             :rows => 1,
             :cols => 40,
            }},
            {:value_asserted => {
             :type => 'text',
             :help => '',
             :rows => 1,
             :cols => 40,
            }},
            {:required => {
             :type => 'text',
             :help => '',
             :rows => 1,
             :cols => 40,
            }},
            {:data_type => {
             :type => 'text',
             :help => '',
             :rows => 1,
             :cols => 40,
             :read_only => true,
            }},
            {:semantic_type => {
             :type => 'text',
             :help => '',
             :rows => 1,
             :cols => 40,
            }},
            {:port_type => {
              :type => 'text',
              :help => '',
              :rows => 1,
              :cols => 40,
            }},
            {:constraints => {
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

