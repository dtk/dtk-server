require File.expand_path('model',  File.dirname(__FILE__))
module XYZ
  class Node < Model
    @@providers ||= Hash.new
    set_relation_name(:node,:node)
    class << self
      def up()
        has_ancestor_field()
        column :is_deployed, :boolean, :default => false
        column :vendor_attributes, :json
        column :architecture, :varchar, :size => 10 #e.g., 'i386'
        column :manifest, :varchar #e.g.,rnp-chef-server-0816-ubuntu-910-x86_32
        column :image_size, :numeric, :size=>[6, 4] #in gigs
        many_to_one :library,:project
        one_to_many :attribute, :node_interface
      end

      ##### Actions
      def discover_and_update(provider_type,filter={})
         unless @@providers[provider_type]
           require File.expand_path("cloud_providers/#{provider_type}/node", File.dirname(__FILE__))
           base_class = XYZ::CloudProvider.const_get provider_type.to_s.capitalize
           @@providers[provider_type] = base_class.const_get "Node" 
         end
         @@providers[provider_type].discover_and_update(filter)
      end

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

    def get_objects_associated_components()
      assocs = Object.get_objects(:assoc_node_component,@c,:node_id => self[:id])
      return [] if assocs.nil?
      assocs.map{|assoc|Object.get_object(IDHandle[:c=>@c,:guid => assoc[:component_id]])}
    end

    def get_contained_attribute_ids(opts={})
      get_directly_contained_object_ids(:attribute)||[]
    end

    def get_direct_attribute_values(type,opts={})
      attr_val_array = self.class.get_objects_wrt_parent(:attribute,id_handle)
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
  class AssocNodeComponent < Model
    set_relation_name(:node,:assoc_node_component)
    class << self
      def up()
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
  	column :info, :json #TBD: temp into we decide exactly what structure we want
        foreign_key :network_partition_id, :network_partition, FK_CASCADE_OPT
        many_to_one :node
        one_to_many :network_address
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
