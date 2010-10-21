module XYZ
  class Action < Model
    set_relation_name(:action,:action)
    def self.up()
      column :transaction, :int, :default => 1 #TODO may introduce transaction object and make this a foreign key
      column :relative_order_order, :int, :default => 1 #relative with respect to parent
      column :change, :json # gives detail about teh change

      #one of thse wil be non null and point to object being changed or added
      foreign_key :node_id, :attribute, FK_CASCADE_OPT
      foreign_key :attribute_id, :attribute, FK_CASCADE_OPT
      foreign_key :component_id, :component, FK_CASCADE_OPT
      #TODO: may have here who, when

      virtual_column :parent_name, :possible_parents => [:datacenter, :action]
      many_to_one :datacenter, :action
      one_to_many :action #nested items show when one change triggers other changes
    end
    ### virtual column defs
    #######################
    #object processing and access functions
    #######################
    def self.create_item(new_id_handle,parent_id_handle,change=nil)
      new_item = {:new_item => new_id_handle, :parent => parent_id_handle}
      new_item.merge!(:change => change) if change
      create_items([new_item]).first
    end
    #assoumption is that all parents are of same type and all changed items of same type
    def self.create_items(new_items)
      return nil if new_items.empty? 
      parent_model_name = new_items.first[:parent][:model_name]
      model_handle = new_items.first[:parent].createMH({:model_name => :action, :parent_model_name => parent_model_name})
      object_model_name = new_items.first[:new_item][:model_name]
      object_id_col = "#{object_model_name}_id".to_sym
      parent_id_col = model_handle.parent_id_field_name()
      change = "new_#{object_model_name}"
      ref_prefix = "action"
      i=0
      rows = new_items.map do |item| 
        ref = "#{ref_prefix}#{(i+=1).to_s}"
        id = item[:new_item].get_id()
        parent_id = item[:parent].get_id()
        hash = {
          :ref => ref,
          :display_name => "change(#{id.to_s})",
          object_id_col => id,
          parent_id_col => parent_id
        }
        item[:change] ? hash.merge(:change => item[:change]) : hash
      end
      create_from_rows(model_handle,rows,{:convert => true})
    end
  end
  class AttributeChange 
    attr_reader :id_handle,:changed_value,:action_id_handle
    def initialize(id_handle,changed_value,action_id_handle)
      @id_handle = id_handle
      @changed_value = changed_value
      @action_id_handle = action_id_handle
    end
  end
end
