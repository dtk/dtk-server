# TODO: better unify with code in model/attribute special processing
module DTK
  class Node
    class NodeAttribute
      def initialize(node)
        @node = node
      end

      def root_device_size()
        ret_value?(:root_device_size)
      end

      def cardinality(opts={})
        ret = ret_value?(:cardinality)
        (opts[:no_default] ? ret : ret||CardinalityDefault)
      end
      CardinalityDefault = 1

      def puppet_version()
        ret_value?(:puppet_version)||R8::Config[:puppet][:version]
      end

      def self.target_ref_attributes_filter()
        TargetRefAttributeFilter
      end
      def self.assembly_template_attribute_filter()
        AssemblyTemplateAttributeFilter
      end
      TargetRefAttributes = ['host_addresses_ipv4','fqdn','node_components','puppet_version','root_device_size']
      TargetRefAttributeFilter = [:oneof,:display_name,TargetRefAttributes]
      NodeTemplateAttributes = ['host_addresses_ipv4','node_components','fqdn']
      AssemblyTemplateAttributeFilter = [:and] + NodeTemplateAttributes.map{|a|[:neq,:display_name,a]}

      module DefaultValue
        def self.host_addresses_ipv4()
          {
            :required => false,
            :read_only => true,
            :is_port => true,
            :cannot_change => false,
            :data_type => 'json',
            :value_derived => [nil],
            :semantic_type_summary => 'host_address_ipv4',
            :display_name =>"host_addresses_ipv4",
            :dynamic =>true,
            :hidden =>true,
            :semantic_type =>{':array'=>'host_address_ipv4'}
          }
        end

        def self.fqdn()
          {
            :required => false,
            :read_only => true,
            :is_port => true,
            :cannot_change => false,
            :data_type => 'string',
            :display_name => 'fqdn',
            :dynamic => true,
            :hidden => true,
          }
        end

        def self.node_components()
          {
            :required => false,
            :read_only => true,
            :is_port => true,
            :cannot_change => false,
            :data_type => 'json',
            :display_name => 'node_components',
            :dynamic => true,
            :hidden => true,
          }
        end
      end


      # for each node, one of following actions is taken
      # - if attribute does not exist, it is created with the given value
      # - if attribute exists but has vlaue differing from 'value' then it is updated
      # - otherwise no-op
      def self.create_or_set_attributes?(nodes,name,value)
        node_idhs = nodes.map{|n|n.id_handle()}
        ndx_attrs = get_ndx_attributes(node_idhs,name)
        to_create_on_node = Array.new
        to_change_attrs = Array.new
        nodes.each do |node|
          if attr = ndx_attrs[node[:id]]
            if existing_val = attr[:attribute_value]
              unless existing_val == value
                to_change_attrs << node
              end
            end
          else
            to_create_on_node << node
          end
        end
        to_change_attrs.each{|attr|attr.update(:value_asserted => val)}
        
        unless to_create_on_node.empty?
          create_rows = to_create_on_node.map{|n|attribute_create_hash(n.id,name,value)}
          attr_mh = to_create_on_node.first.model_handle().create_childMH(:attribute)
          Model.create_from_rows(attr_mh,create_rows,:convert => true)
        end
      end

      def self.cache_attribute_values!(nodes,name)
        nodes_to_query = nodes.reject{|node|Cache.attr_is_set?(node,name)}
        return if nodes_to_query.empty?
        node_idhs = nodes_to_query.map{|n|n.id_handle()}
        ndx_attrs = get_ndx_attributes(node_idhs,name)

        field_info = field_info(name)
        nodes_to_query.each do |node|
          if attr = ndx_attrs[node[:id]]
            if val = attr[:attribute_value]
              Cache.set!(node,val,field_info)
            end
          end
        end
      end

     private
      # attributes indexed by node id
      def self.get_ndx_attributes(node_idhs,name)
        cols = [:id,:node_node_id,:attribute_value]
        field_info = field_info(name)
        filter =  [:eq,:display_name,field_info[:name].to_s]
        Node.get_node_level_attributes(node_idhs,:cols=>cols,:add_filter=>filter).inject(Hash.new) do |h,a|
          h.merge(a[:node_node_id] => a)
        end
      end

      # TODO: need to btter coordinate with code in model/attribute special processing and also the
      # constants in FieldInfo
      def self.attribute_create_hash(node_id,name,value,extra_fields={})
        unless extra_fields.empty?
          raise Error.new("extra_fields with args not treated yet")
        end
        name = name.to_s
        {:ref => name,
          :display_name => name,
          :value_asserted => value,
          :node_node_id => node_id
        }
      end

      FieldInfo = {
        :cardinality => {:name => :cardinality, :semantic_type => :integer},
        :root_device_size => {:name => :root_device_size, :semantic_type => :integer},
        :puppet_version => {:name => :puppet_version}
      }

      def self.field_info(name)
        unless ret = FieldInfo[name.to_sym]
          raise Error.new("No node attribute with name (#{name})")
        end
        ret
      end
      def field_info(name)
        self.class.field_info(name)
      end

      def ret_value?(name)
        field_info = field_info(name)
        if Cache.attr_is_set?(@node,name)
          Cache.get(@node,name)
        else
          raw_val = get_raw_value?(name)
          Cache.set!(@node,raw_val,field_info)
        end
      end

      def get_raw_value?(name)
        attr = @node.get_node_attribute?(name.to_s,:cols => [:id,:group_id,:attribute_value])
        attr && attr[:attribute_value]
      end

      module Cache
        def self.attr_is_set?(node,name)
          (node[CacheKeyOnNode]||{}).has_key?(name.to_sym)
        end
        def self.get(node,name)
          (node[CacheKeyOnNode]||{})[name.to_sym]
        end
        def self.set!(node,raw_val,field_info)
          name = field_info[:name]
          semantic_data_type = field_info[:semantic_type]
          val =
            if raw_val and semantic_data_type
              Attribute::SemanticDatatype.convert_to_internal_form(semantic_data_type,raw_val)
            else
              raw_val
            end
          (node[CacheKeyOnNode] ||= Hash.new)[name.to_sym] = val
        end
        CacheKeyOnNode = :attribute_value_cache
      end
    end

    module AttributeClassMixin

      def cache_attribute_values!(nodes,name)
        NodeAttribute.cache_attribute_values!(nodes,name)
      end

      # target_ref_attributes are ones used on target refs and can also be on instances
      def get_target_ref_attributes(node_idhs,opts={})
        cols = opts[:cols] || [:id,:display_name,:node_node_id,:attribute_value,:data_type]
        add_filter = NodeAttribute.target_ref_attributes_filter()
        get_node_level_attributes(node_idhs,:cols=>cols,:add_filter=>add_filter)
      end

      # node_level_assembly_template_attributes are ones that are persisted in service modules
      def get_node_level_assembly_template_attributes(node_idhs,opts={})
        cols = opts[:cols] || [:id,:display_name,:node_node_id,:attribute_value,:data_type]
        add_filter = NodeAttribute.assembly_template_attribute_filter()
        get_node_level_attributes(node_idhs,:cols=>cols,:add_filter=>add_filter)
      end

      def get_node_level_attributes(node_idhs,opts={})
        ret = Array.new
        return ret if node_idhs.empty?()
        filter = [:oneof,:node_node_id,node_idhs.map{|idh|idh.get_id()}]
        if add_filter = opts[:add_filter]
          filter = [:and,filter,add_filter]
        end
        cols = opts[:cols] || [:id,:group_id,:display_name,:required]
        sp_hash = {
          :cols => cols,
          :filter => filter,
        }
        attr_mh = node_idhs.first.createMH(:attribute)
        opts = (cols.include?(:ref) ? {:keep_ref_cols => true} : {})
        get_objs(attr_mh,sp_hash,opts)
      end

      def get_virtual_attributes(attrs_to_get,cols,field_to_match=:display_name)
        ret = Hash.new
        # TODO: may be able to avoid this loop
        attrs_to_get.each do |node_id,hash_value|
          attr_info = hash_value[:attribute_info]
          node = hash_value[:node]
          attr_names = attr_info.map{|a|a[:attribute_name].to_s}
          rows = node.get_virtual_attributes(attr_names,cols,field_to_match)
          rows.each do |attr|
            attr_name = attr[field_to_match]
            ret[node_id] ||= Hash.new
            ret[node_id][attr_name] = attr
          end
        end
        ret
      end

      # TODO: need tp fix up below; maybe able to deprecate
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
	    cmp[:external_ref] ? {:external_ref => cmp[:external_ref]} : {}
	  values = cmp.get_direct_attribute_values(:value,{:attr_include => [:external_ref]})
	  ret[:component][cmp_ref][:attribute] = values if values
        }
        ret
      end
    end

    module AttributeMixin
      def attribute()
        NodeAttribute.new(self)
      end

      def get_node_attribute?(attribute_name,opts={})
        get_node_attributes(opts.merge(:filter => [:eq,:display_name,attribute_name])).first
      end
      def get_node_attributes(opts={})
        Node.get_node_level_attributes([id_handle()],:cols=>opts[:cols],:add_filter=>opts[:filter])
      end

      # TODO: stub; see if can use get_node_attributes
      def get_node_attributes_stub()
        Array.new
      end
      # TODO: once see calling contex, remove stub call
      def get_node_and_component_attributes(opts={})
        node_attrs = get_node_attributes_stub()
        component_attrs = get_objs(:cols => [:components_and_attrs]).map{|r|r[:attribute]}
        component_attrs + node_attrs
      end


      def set_attributes(av_pairs)
        Attribute::Pattern::Node.set_attributes(self,av_pairs)
      end

      def get_attributes_print_form(opts={})
        if filter = opts[:filter]
          case filter
          when :required_unset_attributes
            get_attributes_print_form_aux(lambda{|a|a.required_unset_attribute?()})
          else
            raise Error.new("not treating filter (#{filter}) in Assembly::Instance#get_attributes_print_form")
          end
        else
          get_attributes_print_form_aux()
        end
      end

      def get_attributes_print_form_aux(filter_proc=nil)
        node_attrs = get_node_attributes_stub()
        component_attrs = get_objs(:cols => [:components_and_attrs]).map do |r|
          attr = r[:attribute]
          # TODO: more efficient to have sql query do filtering
          if filter_proc.nil? or filter_proc.call(attr)
            display_name_prefix = "#{r[:component].display_name_print_form()}/"
            attr.print_form(Opts.new(:display_name_prefix => display_name_prefix))
          end
        end.compact
        (component_attrs + node_attrs).sort{|a,b|a[:display_name] <=> b[:display_name]}
      end
      private :get_attributes_print_form_aux

      def get_virtual_attribute(attribute_name,cols,field_to_match=:display_name)
        sp_hash = {
          :model_name => :attribute,
          :filter => [:eq, field_to_match, attribute_name],
          :cols => cols
        }
        get_children_from_sp_hash(:attribute,sp_hash).first
      end
      # TODO: may write above in terms of below
      def get_virtual_attributes(attribute_names,cols,field_to_match=:display_name)
        sp_hash = {
          :model_name => :attribute,
          :filter => [:oneof, field_to_match, attribute_names],
          :cols => Aux.array_add?(cols,field_to_match)
        }
        get_children_from_sp_hash(:attribute,sp_hash)
      end

      # attribute on component on node
      # assumption is that component cannot appear more than once on node
      def get_virtual_component_attribute(cmp_assign,attr_assign,cols)
        base_sp_hash = {
          :model_name => :component,
          :filter => [:and, [:eq, cmp_assign.keys.first,cmp_assign.values.first],[:eq, :node_node_id,self[:id]]],
          :cols => [:id]
        }
        join_array =
          [{
             :model_name => :attribute,
             :convert => true,
             :join_type => :inner,
             :filter => [:eq, attr_assign.keys.first,attr_assign.values.first],
           :join_cond => {:component_component_id => :component__id},
             :cols => cols.include?(:component_component_id) ? cols : cols + [:component_component_id]
           }]
        row = Model.get_objects_from_join_array(model_handle.createMH(:component),base_sp_hash,join_array).first
        row && row[:attribute]
      end



      ####Things below heer shoudl be cleaned up or deprecated
      #####
      # TODO: should be centralized
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

      ################
      # TODO: may be aqble to deprecate most or all of below
      ### helpers
      def ds_attributes(attr_list)
        [:ds_attributes]
      end
      # TODO: rename subobject to sub_object
      def is_ds_subobject?(relation_type)
        false
      end
      ##########

     private
      def check_and_ret_title_attribute_name?(component_template,component_title)
        title_attr_name = component_template.get_title_attribute_name?()
        if component_title and title_attr_name.nil?
          raise ErrorUsage.new("Component (#{component_template.component_type_print_form()}) given a title but should not have one")
        elsif component_title.nil? and title_attr_name
          cmp_name = component_template.component_type_print_form()
          raise ErrorUsage.new("Component (#{cmp_name}) needs a title; use form #{cmp_name}[TITLE]")
        end

        if title_attr_name #and component_title
          component_type = component_template.get_field?(:component_type)
          if existing_cmp = Component::Instance.get_matching?(id_handle(),component_type,component_title)
            raise ErrorUsage.new("Component (#{existing_cmp.print_form()}) already exists")
          end
        end

        title_attr_name
      end
    end
  end
end
