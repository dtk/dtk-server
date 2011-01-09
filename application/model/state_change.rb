module XYZ
  class StateChange < Model
    set_relation_name(:action,:state_change)
    def self.up()
      column :state, :varchar, :size => 15, :default => "pending" # | "executing" | "completed"
      column :mode, :varchar, :size => 15, :default => "declarative" # | "procedural"
      column :type, :varchar, :size => 25# "setting" | "delete" | "deploy-node" | "install-component" | "patch-component" | "upgare-component" | "rollback-component" | "procedure" | .. 
      column :base_object, :json
      #TODO; may rename
      column :object_type, :varchar, :size => 15 # "attribute" | "node" | "component"

      #TODO: may change below to more general json field about (partial) ordering
      column :relative_order, :int, :default => 1 #relative with respect to parent
      column :change, :json # gives detail about the change

      virtual_column :parent_name, :possible_parents => [:datacenter,:state_change]
      virtual_column :old_value, :path => [:change, :old]
      virtual_column :new_value, :path => [:change, :new]

      virtual_column :qualified_parent_name, :type => :varchar, :local_dependencies => [:base_object]

      #one of thse wil be non null and point to object being changed or added
      foreign_key :node_id, :node, FK_CASCADE_OPT
      foreign_key :attribute_id, :attribute, FK_CASCADE_OPT
      foreign_key :component_id, :component, FK_CASCADE_OPT
      #TODO: may have here who, when

      #TODO: example converted form; apply to rest of vcs
      virtual_column :created_node,:type => :json, :hidden => true,
        :remote_dependencies =>
        [
         {
           :model_name => :node,
           :join_type => :inner,
           :join_cond=>{:id=> q(:state_change,:node_id)},
           :cols=>[:id, :display_name, :external_ref, id(:datacenter),:ancestor_id]
         },
         {
           :model_name => :datacenter,
           :join_type => :inner,
           :join_cond=>{:id=> p(:node,:datacenter)},
           :cols=>[:id, :display_name]
         },
         {
           :model_name => :node,
           :alias => :image,
           :join_type => :inner,
           :join_cond=>{:id=> q(:node,:ancestor_id)},
           :cols=>[:id, :display_name,:external_ref]
         }
        ]


      virtual_column :installed_component, :type => :json, :hidden => true,
        :remote_dependencies =>
        [
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> q(:state_change,:component_id)},
           :cols=>[:id, :display_name, :external_ref, id(:node), :only_one_per_node]
         },
         {
           :model_name => :node,
           :join_type => :inner,
           :join_cond=>{:id=> p(:component,:node)},
           :cols=>[:id, :display_name, :external_ref]
         }
        ]

      virtual_column :changed_attribute, :type => :json, :hidden => true,
        :remote_dependencies =>
        [
         {
           :model_name => :attribute,
           :join_type => :inner,
           :join_cond=> {:id => q(:state_change,:attribute_id)},
           :cols=>[:id, id(:component)]
         },
         {
           :model_name => :component,
           :join_type => :inner,
           :join_cond=>{:id=> p(:attribute,:component)},
           :cols=>[:id, :display_name, :external_ref, id(:node), :only_one_per_node]
         },
         {
           :model_name => :node,
           :join_type => :inner,
           :join_cond=>{:id=> p(:component,:node)},
           :cols=>[:id, :display_name, :external_ref]
         }
        ]

      many_to_one :datacenter, :state_change
      one_to_many :state_change #that is for decomposition 
    end
    ### virtual column defs
    #######################


    def qualified_parent_name()
      base =  self[:base_object]
      return nil unless base
      node_or_ng = (base[:node]||{})[:display_name]||(base[:node_group]||{})[:display_name]
      component = (base[:component]||{})[:display_name]
      return nil if node_or_ng.nil? and component.nil?
      [node_or_ng,component].compact.join("/")
    end

    #object processing and access functions
    #######################
    def on_node_config_agent_type()
      #TODO: stub
      :chef
    end
    def create_node_config_agent_type()
      #TODO: stub
      :ec2
    end

    def self.state_changes_are_concurrent?(state_change_list)
      rel_order = state_change_list.map{|x|x[:relative_order]}
      val = rel_order.shift
      rel_order.each{|x|return nil unless x == val}
      true
    end


    def self.create_pending_change_item(new_item_hash)
      create_pending_change_items([new_item_hash]).first
    end
    #assoumption is that all parents are of same type and all changed items of same type
    def self.create_pending_change_items(new_item_hashes)
      return nil if new_item_hashes.empty? 
      parent_model_name = new_item_hashes.first[:parent][:model_name]
      model_handle = new_item_hashes.first[:parent].createMH({:model_name => :state_change, :parent_model_name => parent_model_name})
      object_model_name = new_item_hashes.first[:new_item][:model_name]
      object_id_col = "#{object_model_name}_id".to_sym
      parent_id_col = model_handle.parent_id_field_name()
      type = 
        case object_model_name
          when :attribute then "setting"
          when :component then "install-component"
          when :node then "create_node"
          else raise ErrorNotImplemented.new("when object type is #{object_model_name}")
      end 
      display_name_prefix = 
        case object_model_name
          when :attribute then "setting-attribute"
          when :component then "install-component"
          when :node then "create_node"
      end 
      
      ref_prefix = "state_change"
      i=0
      rows = new_item_hashes.map do |item| 
        ref = "#{ref_prefix}#{(i+=1).to_s}"
        id = item[:new_item].get_id()
        parent_id = item[:parent].get_id()
        display_name = display_name_prefix + (item[:new_item][:display_name] ? "(#{item[:new_item][:display_name]})" : "")
        hash = {
          :ref => ref,
          :display_name => display_name,
          :base_object => item[:base_object],
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
    attr_reader :id_handle,:changed_value,:state_change_id_handle
    def initialize(id_handle,changed_value,state_change_id_handle)
      @id_handle = id_handle
      @changed_value = changed_value
      @state_change_id_handle = state_change_id_handle
    end
  end
end
