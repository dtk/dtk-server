module XYZ
  class PendingChangeItem < Model
    set_relation_name(:pending_change,:item)
    def self.up()
      column :transaction, :int, :default => 1 #TODO may introduce transaction object and make this a foreign key
      column :relative_order_order, :int, :default => 1 #relative with respect to parent
      column :change, :json # gives detail about teh change

      #one oif thse wil be non null and point to object being changed or added
      foreign_key :attribute_id, :attribute, FK_CASCADE_OPT
      foreign_key :component_id, :component, FK_CASCADE_OPT

      #NOTE: may have here who, when
      many_to_one :datacenter, :pending_change_item, :library, :project #TODO: library and project just included temporarily for testing
      one_to_many :pending_change_item #nested items show when one change triggers other changes
    end
    ### virtual column defs
    #######################
    #object processing and access functions
    #######################
    def self.create_items(new_id_handles,target_id_handle)
      return nil if new_id_handles.empty?
      parent_idh = target_id_handle.get_parent_id_handle()
      pending_item_mh = target_id_handle.createMH({:model_name => :pending_change_item, :parent_model_name => parent_idh[:model_name]})
      model_name = new_id_handles.first[:model_name]
      object_id_col = "#{model_name}_id".to_sym
      parent_id = parent_idh.get_id()
      parent_id_col = pending_item_mh.parent_id_field_name()
      change = "new_#{model_name}"
      ref_prefix = "pending_change_item"
      i=0
      rows = new_id_handles.map do |idh| 
        ref = "#{ref_prefix}#{(i+=1).to_s}"
        id = idh.get_id()
        {:ref => ref,
          :display_name => "change(#{id.to_s})",
          object_id_col => id,
          parent_id_col => parent_id
        }
      end
      create_from_rows(pending_item_mh,rows,parent_idh)
    end
  end
end
