module XYZ
  class Node < Model
    extend ClassMixinDataSourceExtensions
    set_relation_name(:node,:node)
    class << self
#TODO: move this out into central model, should read off of model meta data for processing
      def up()
        has_ancestor_field()
        column :ds_attributes, :json, :hidden => true
        column :ds_key, :varchar, :hidden => true
        column :data_source, :varchar, :size => 25
        column :ds_source_obj_type, :varchar, :size => 25
        column :type, :varchar, :size => 15, :default => "instance" # instance or template
        column :os, :varchar, :size => 25
        column :is_deployed, :boolean
        column :architecture, :varchar, :size => 10 #e.g., 'i386'
       #TBD: in data source specfic now column :manifest, :varchar #e.g.,rnp-chef-server-0816-ubuntu-910-x86_32
        #TBD: experimenting whetehr better to make this actual or virtual columns
        column :image_size, :numeric, :size=>[8, 3] #in megs
        column :ui, :json
        virtual_column :parent_name, :possible_parents => [:library,:project]
        virtual_column :disk_size #in megs
        #TBD: can these virtual columns just be inherited
        foreign_key :data_source_id, :data_source, FK_SET_NULL_OPT
        many_to_one :library,:project
        one_to_many :attribute, :node_interface, :address_access_point, :monitoring_item
      end

      def ds_attributes(attr_list)
        [:ds_attributes]
      end
#TODO: rename subobject to sub_object
      def is_ds_subobject?(relation_type)
        false
      end


      #TODO: quick hack
      def get_wspace_display(id_handle)
        c = id_handle[:c]
        node_id = IDInfoTable.get_id_from_id_handle(id_handle)
        node = get_objects(ModelHandle.new(c,:node),{:id => node_id}).first

        assoc_node_component_ds = get_objects_just_dataset(ModelHandle.new(c,:assoc_node_component),{:node_id => node_id})
        component_ds = get_objects_just_dataset(ModelHandle.new(c,:component),nil,{:field_set => Model::FieldSet.default(:component)})
        assoc_comps = assoc_node_component_ds.graph(:inner,component_ds,{:id => :component_id}).all
        node.merge(:component => assoc_comps.inject({}){|h,o|h.merge(o[:component][:id] => o[:component])})
      end

      ##### Actions

      def get_node_attribute_values(id_handle,opts={})
	c = id_handle[:c]
        node_obj = get_object(id_handle,opts)
        raise Error.new("node associated with (#{id_handle}) not found") if node_obj.nil? 	
	ret = node_obj.get_direct_attribute_values(:value) || {}

	cmps = node_obj.get_objects_associated_components()
	cmps.each{|cmp|
	  ret[:component]||= {}
	  cmp_ref = cmp.get_qualified_ref.to_sym
	  ret[:component][cmp_ref] = 
	    cmp[:external_cmp_ref] ? {:external_cmp_ref => cmp[:external_cmp_ref]} : {}
	  values = cmp.get_direct_attribute_values(:value,{:attr_include => [:external_attr_ref]})
	  ret[:component][cmp_ref][:attribute] = values if values 
        }
        ret
      end
    end

    ### virtual column defs
    # returns asserted first then derived
    def disk_size()
      self.class.nested_value(self[:ds_attributes],[:flavor,:disk])
    end
    def parent_name()
      return "library/#{self[:library][:display_name]}" if self[:library] and self[:library][:display_name]
      return "project/#{self[:project][:display_name]}" if self[:project] and self[:project][:display_name]
      nil
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

#TODO: need to cleanup and move sub models/relationships out of here

module XYZ
  class AssocNodeComponent < Model
    set_relation_name(:node,:assoc_node_component)
    class << self
      def up()
        column :ds_attributes, :json
        column :ds_key, :varchar
        foreign_key :node_id, :node, FK_CASCADE_OPT
        foreign_key :component_id, :component, FK_CASCADE_OPT
        many_to_one :library, :project
      end

      ##### Actions
      def create(target_id_handle,node_id_handle,component_id_handle,href_prefix,opts={})
        raise Error.new("Target location (#{target_id_handle}) does not exist") unless exists? target_id_handle
	node =  get_instance_scalar_values(node_id_handle,opts)
	raise Error.new("Node (#{node_id_handle}) does not exist") if node.nil?

	component =  get_instance_scalar_values(component_id_handle,opts)
	raise Error.new("Component (#{component_id_handle} does not exist") if component.nil?

	node_attrs = node[n_ref = node.keys.first]
	component_attrs = component[c_ref = component.keys.first]
	assoc_content = {:node_id => node_attrs[:id],:component_id => component_attrs[:id]}
	assoc_ref = (n_ref.to_s + "__" + c_ref.to_s).to_sym

	factory_id_handle = get_factory_id_handle(target_id_handle,:assoc_node_component)
	create_from_hash(factory_id_handle,{assoc_ref => assoc_content})
      end

    end
  end
end


module XYZ
  class NodeInterface < Model
    set_relation_name(:node,:interface)
    class << self
      def up()
  	column :type, :varchar, :size => 25 #ethernet, vlan, ...
        column :address, :json #e.g., {:family : "ipv4, :address : "10.4.5.7", "mask" : 255.255.255.0"}
        foreign_key :network_partition_id, :network_partition, FK_CASCADE_OPT
        many_to_one :node, :node_interface
        one_to_many :node_interface
      end

      ##### Actions
    end
  end
end


#TBD: may move
module XYZ
  class NodeGroup < Model
    set_relation_name(:node,:node_group)
    class << self
      def up()
        many_to_one :library, :project
      end

      ##### Actions
    end
  end

  class NodeGroupMember < Model
    set_relation_name(:node,:node_group_member)
    class << self
      def up()
	foreign_key :node_id, :node, FK_CASCADE_OPT
	foreign_key :node_group_id, :node_group, FK_CASCADE_OPT
        many_to_one :library, :project
      end

      ##### Actions
    end
  end

end
