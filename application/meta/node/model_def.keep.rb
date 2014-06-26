
{
  :has_ancestor_field=>true,
  :implements_owner=>true,
  :field_defs => [
    {:display_name=>{
        :type=>:text,
        :size=>50,
      }
    },
    {:tag=>{
        :type=>:text,
        :size=>25,
      }
    },
    {:type=>{
        :type=>:select,
        :size=>25,
        :default=> "instance"
      }
    },
    {:os=>{
        :type=>:text,
        :size=>25,
      }
    },
    {:is_deployed=>{
        :type=>:boolean,
      }
    },
    {:architecture=>{
        :type=>:text,
        :size=>10,
      }
    },
    {:image_size=>{
        :type=>:numeric,
        :size=>[8,3]
      }
    },
    {:operational_status=>{
        :type=>:select,
        :size=>50
      }
    },
    {:disk_size=>{
        :type=>:foo,
      }
    },
    {:ui=>{
        :type=>:json,
      }
    },
    {:parent_name=>{
        :type=>:json,
        :no_column=>true
      }
    },
    {:parent_id=>{
        :type=>:related
      }
    },
  ],
  :relationships =>[

  ]
}
=begin
      column :ui, :json
      virtual_column :parent_name, :possible_parents => [:library,:datacenter,:project]
      virtual_column :disk_size, :path => [:ds_attributes,:flavor,:disk] #in megs
      # TODO how to have this conditionally "show up"
      virtual_column :ec2_security_groups, :path => [:ds_attributes,:groups] 

      foreign_key :data_source_id, :data_source, FK_SET_NULL_OPT
      many_to_one :library, :datacenter, :project
      one_to_many :attribute, :component, :node_interface, :address_access_point, :monitoring_item
=end