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
    def self.create(new_idhs,target_idh)
      return nil if new_idhs.empty?
      parent_idh = target_idh.get_parent_id_handle()
      pending_item_mh = target_idh.createMH({:model_name => :pending_item, :parent_model_name => parent_idh[:model_name]})
      model_name = new_idhs.first[:model_name]
      object_id_col = "#{model_name}_id".to_sym
      change = "new_#{model_name}"
      ref_prefix = "pending_change_item"
      i=0
      rows = new_idhs.map do |idh| 
        ref = "#{ref_prefix}#{(i+=1).to_s}"
        id = idh.get_id()
        {:ref => ref,
          :display_name => "change(#{id.to_s})",
          object_id_col => id
        }
      end
      create_from_rows(pending_item_mh,rows,parent_idh)
    end
  end
end
