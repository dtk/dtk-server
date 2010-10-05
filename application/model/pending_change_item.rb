module XYZ
  class PendingChangeItem < Model
    set_relation_name(:pending_change,:item)
    def self.up()
      column :transaction, :int #TODO may introduce transaction object and make this a foreign key
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
  end
end
