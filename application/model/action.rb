module XYZ
  class Action < Model
    set_relation_name(:action,:action)
    def self.up()
      column :state, :varchar, :size => 15, :default => "pending" # | "executing" | "completed"
      column :mode, :varchar, :size => 15, :default => "declarative" # | "procedural"
      column :type, :varchar, :size => 25# "setting" | "delete" | "deploy-node" | "install-component" | "patch-component" | "upgare-component" | "rollback-component" | "procedure" | .. 
      column :object_type, :varchar, :size => 15 # "attribute" | "node" | "component"
      column :transaction, :int, :default => 1 #TODO may introduce transaction object and make this a foreign key
      #TODO: change below to more general json field about ordering
      column :relative_order_order, :int, :default => 1 #relative with respect to parent
      column :change, :json # gives detail about the change

      virtual_column :parent_name, :possible_parents => [:datacenter,:action]
      virtual_column :old_value, :path => [:change, :old]
      virtual_column :new_value, :path => [:change, :new]

      #one of thse wil be non null and point to object being changed or added
      foreign_key :node_id, :attribute, FK_CASCADE_OPT
      foreign_key :attribute_id, :attribute, FK_CASCADE_OPT
      foreign_key :component_id, :component, FK_CASCADE_OPT
      #TODO: may have here who, when

      many_to_one :datacenter, :action
      one_to_many :action #that is for decomposition #todo: what about for ordering
    end
    ### virtual column defs
    #######################
    #object processing and access functions
    #######################
    def self.create_pending_change_item(new_id_handle,parent_id_handle,change=nil)
      new_item = {:new_item => new_id_handle, :parent => parent_id_handle}
      new_item.merge!(:change => change) if change
      create_pending_change_items([new_item]).first
    end
    #assoumption is that all parents are of same type and all changed items of same type
    def self.create_pending_change_items(new_items)
      return nil if new_items.empty? 
      parent_model_name = new_items.first[:parent][:model_name]
      model_handle = new_items.first[:parent].createMH({:model_name => :action, :parent_model_name => parent_model_name})
      object_model_name = new_items.first[:new_item][:model_name]
      object_id_col = "#{object_model_name}_id".to_sym
      parent_id_col = model_handle.parent_id_field_name()
      type = 
        case object_model_name
          when :attribute then "setting"
          when :component then "install-component"
          else raise ErrorNotImplemented.new("when object type is #{object_model_name}")
      end 
      display_name_prefix = 
        case object_model_name
          when :attribute then "setting-attribute"
          when :component then "install-component"
      end 
      
      ref_prefix = "action"
      i=0
      rows = new_items.map do |item| 
        ref = "#{ref_prefix}#{(i+=1).to_s}"
        id = item[:new_item].get_id()
        parent_id = item[:parent].get_id()
        display_name = display_name_prefix + (item[:new_item][:display_name] ? "(#{item[:new_item][:display_name]})" : "")
        hash = {
          :ref => ref,
          :display_name => display_name,
          :state => "pending",
          :mode => "declarative",
          :type => type,
          :object_type => object_model_name.to_s,
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
