module XYZ
  class Node < Model
#    extend ClassMixinDataSourceExtensions
    set_relation_name(:node,:node)
#TODO: move this out into central model, should read off of model meta data for processing
    def self.up()
      has_ancestor_field()
      ds_column_defs :ds_attributes, :ds_key, :data_source, :ds_source_obj_type
      external_ref_column_defs()
      column :tag,  :varchar
      column :type, :varchar, :size => 25, :default => "instance" # | "image" | "staged" | "constraint" | "contraint-common-node"
      column :os, :varchar, :size => 25
      #TODO: is_deployed may just be a virtual column that tests if :external_ref is null
      column :is_deployed, :boolean
      column :architecture, :varchar, :size => 10 #e.g., 'i386'
      #TBD: in data source specfic now column :manifest, :varchar #e.g.,rnp-chef-server-0816-ubuntu-910-x86_32
      #TBD: experimenting whetehr better to make this actual or virtual columns
      column :image_size, :numeric, :size=>[8, 3] #in megs
      column :operational_status, :varchar, :size => 50
      column :ui, :json
      virtual_column :parent_name, :possible_parents => [:library,:datacenter,:project]
      virtual_column :disk_size, :path => [:ds_attributes,:flavor,:disk] #in megs
      #TODO how to have this conditionally "show up"
      virtual_column :ec2_security_groups, :path => [:ds_attributes,:groups] 

      foreign_key :data_source_id, :data_source, FK_SET_NULL_OPT
      many_to_one :library, :datacenter, :project
      one_to_many :attribute, :component, :node_interface, :address_access_point, :monitoring_item
    end

    ### virtual column defs
    #######################
    #object processing and access functions
    def self.add_model_specific_override_attrs!(override_attrs)
      override_attrs[:type] = "staged"

      override_attrs[:ref] = SQL::ColRef.concat("s-",:ref)
      override_attrs[:display_name] = SQL::ColRef.qualified_ref
      #a possible replacement for 2 above
      # override_attrs[:display_name] = SQL::ColRef.concat{|o|["s-",o.qualified_ref]}

      override_attrs[:external_ref] = nil
    end

    def self.clone_post_copy_hook(new_id_handle,target_id_handle,opts={})
      parent_action_id_handle = target_id_handle.get_parent_id_handle()
      Action.create_pending_change_item(:new_item => new_id_handle, :parent => parent_action_id_handle)
    end
    
    #TODO: quick hack
    def self.get_wspace_display(id_handle)
      node_id = IDInfoTable.get_id_from_id_handle(id_handle)
      node_mh = id_handle.createMH(:model_name => :node)
      node = get_objects(node_mh,{:id => node_id}).first

      component_mh = node_mh.createMH(:model_name => :component)
      component_ds = get_objects_just_dataset(component_mh,{:node_node_id => node_id})
      attr_where_clause = SQL.or({:port_type => "input"},{:port_type => "output"})
      #TODO: can prune what fields included
      attr_fs = Model::FieldSet.default(:attribute).add_cols(:component_component_id)
      attribute_mh = node_mh.createMH(:model_name => :attribute)
      attribute_ds = get_objects_just_dataset(attribute_mh,attr_where_clause,FieldSet.opt(attr_fs))
      components = component_ds.graph(:left_outer,attribute_ds,{:component_component_id => :id}).all
      node.merge(:component => components)
    end
    #######################
#TODO: may be aqble to deprecate most or all of below
      ### helpers
      def ds_attributes(attr_list)
        [:ds_attributes]
      end
      #TODO: rename subobject to sub_object
      def is_ds_subobject?(relation_type)
        false
      end


      ##### Actions
#TODO: need tp fix up below
      def self.get_node_attribute_values(id_handle,opts={})
	c = id_handle[:c]
        node_obj = get_object(id_handle,opts)
        raise Error.new("node associated with (#{id_handle}) not found") if node_obj.nil? 	
	ret = node_obj.get_direct_attribute_values(:value) || {}

	cmps = node_obj.get_objects_associated_components()
	cmps.each{|cmp|
	  ret[:component]||= {}
	  cmp_ref = cmp.get_qualified_ref.to_sym
	  ret[:component][cmp_ref] = 
	    cmp[:external_ref] ? {:external_ref => cmp[:external_ref]} : {}
	  values = cmp.get_direct_attribute_values(:value,{:attr_include => [:external_ref]})
	  ret[:component][cmp_ref][:attribute] = values if values 
        }
        ret
      end

    #######

#TODO: should this be more generic and centralized?
    def get_objects_associated_components()
      assocs = Model.get_objects(ModelHandle.new(@c,:assoc_node_component),:node_id => self[:id])
      return [] if assocs.nil?
      assocs.map{|assoc|Model.get_object(IDHandle[:c=>@c,:guid => assoc[:component_id]])}
    end

#TODO: should be centralized
    def get_contained_attribute_ids(opts={})
      get_directly_contained_object_ids(:attribute)||[]
    end

    def get_direct_attribute_values(type,opts={})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      attr_val_array = Model.get_objects(ModelHandle.new(@c,:attribute),nil,:parent_id => parent_id)
      return nil if attr_val_array.nil?
      return nil if attr_val_array.empty?
      hash_values = {}
      attr_type = {:asserted => :value_asserted, :derived => :value_derived, :value => :attribute_value}[type]
      attr_val_array.each{|attr|
        hash_values[attr.get_qualified_ref.to_sym] =
          {:value => attr[attr_type],:id => attr[:id]}
      }
      {:attribute => hash_values}
    end
  end
end

module XYZ
  class NodeInterface < Model
    set_relation_name(:node,:interface)
    def self.up()
      column :type, :varchar, :size => 25 #ethernet, vlan, ...
      column :address, :json #e.g., {:family : "ipv4, :address : "10.4.5.7", "mask" : 255.255.255.0"}
      foreign_key :network_partition_id, :network_partition, FK_CASCADE_OPT
      many_to_one :node, :node_interface
      one_to_many :node_interface
    end
    ### virtual column defs
    #######################
    ### object access functions
    #######################
  end
end



