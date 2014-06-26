#    set_relation_name(:data_source,:entry)
    class << self
      def up()
        column :ds_name, :varchar, :size => 25 #TBD: just passed in for convenient access; 'inherited' from its conatiner
        column :obj_type, :varchar, :size => 25 
        # used when multiple source objects can map to same normaized object such as for ec2 image and instance both map to node
        column :source_obj_type, :varchar, :size => 25 
        column :ds_is_golden_store, :boolean, :default => true
        column :update_policy, :varchar, :size =>25 #indicates whether inventory is updated onmanual, automatic, user_approval_for_delete, user_approval_for_add, user_approval_for_change (plus automitcally delete objects not put in thru our tool  
        column :filter, :json #intended to capture the "what"
        column :polling_policy, :json
        foreign_key :polling_task_id, :task, FK_SET_NULL_OPT
        column :placement_location, :json #intended top capture the where such as put in top level or in container or associate with some group or tag; default is the container of the root data source object
        many_to_one :data_source, :data_source_entry
        one_to_many :data_source_entry
      end
    end
