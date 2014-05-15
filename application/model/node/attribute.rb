module DTK
  class Node
    class NodeAttribute
      r8_nested_require('attribute','def')
      #must be ordered this way
      r8_nested_require('attribute','declarations')

      def initialize(node)
        @node = node
      end

      def root_device_size()
        get_value?(CanonicalName::RootDeviceSize,:integer)
      end
      
      def puppet_version()
        get_value?(CanonicalName::PuppetVersion)||R8::Config[:puppet][:version]
      end

      def self.assembly_attribute_filter()
        AssemblyAttributeFilter
      end
      NodeTemplateAttributes = ['host_addresses_ipv4','node_components','fqdn']
      AssemblyAttributeFilter = [:and] + NodeTemplateAttributes.map{|a|[:neq,:display_name,a]}

     private
      def get_value?(canonical_attr_name,semantic_data_type=nil)
        aliases = canonical_attr_name.aliases
        attribute_names = (aliases ? [canonical_attr_name] + aliases : canonical_attr_name)
        attr = @node.get_node_attribute?(attribute_names,:cols => [:id,:group_id,:attribute_value])
        value = attr && attr[:attribute_value]
        if value and semantic_data_type
          value = Attribute::SemanticDatatype.convert_to_internal_form(semantic_data_type,value)
        end
        value
      end
    end

    module AttributeClassMixin
      #node_level_assembly_attributes are ones that are persited on assembly logical nodes, not node template
     def get_node_level_assembly_attributes(node_idhs,cols=nil)
       cols ||= [:id,:display_name,:node_node_id,:attribute_value]
       add_filter = NodeAttribute.assembly_attribute_filter()
       get_node_level_attributes(node_idhs,cols,add_filter)
     end

     def get_node_level_attributes(node_idhs,cols=nil,add_filter=nil)
        ret = Array.new
        return ret if node_idhs.empty?()
        filter = [:oneof,:node_node_id,node_idhs.map{|idh|idh.get_id()}]
        if add_filter
          filter = [:and,filter,add_filter]
        end
        sp_hash = {
          :cols => cols||[:id,:group_id,:display_name,:required],
          :filter => filter,
        }
        attr_mh = node_idhs.first.createMH(:attribute)
        get_objs(attr_mh,sp_hash)
      end

      def get_virtual_attributes(attrs_to_get,cols,field_to_match=:display_name)
        ret = Hash.new
        #TODO: may be able to avoid this loop
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

      #TODO: need tp fix up below; maybe able to deprecate
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

      def get_node_attribute?(attribute_name_or_names,opts={})
       name_filter = 
          if attribute_name_or_names.kind_of?(Array)
            [:or] + attribute_name_or_names.map{|attr|[:eq,:display_name,attr]}
          else
            [:eq,:display_name,attribute_name_or_name]
          end
        get_node_attributes(opts.merge(:filter => name_filter)).first
      end
      def get_node_attributes(opts={})
        Node.get_node_level_attributes([id_handle()],opts[:cols],opts[:filter])
      end

      #TODO: stub; see if can use get_node_attributes
      def get_node_attributes_stub()
        Array.new 
      end
      #TODO: once see calling contex, remove stub call
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
          #TODO: more efficient to have sql query do filtering
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
      #TODO: may write above in terms of below
      def get_virtual_attributes(attribute_names,cols,field_to_match=:display_name)
        sp_hash = {
          :model_name => :attribute,
          :filter => [:oneof, field_to_match, attribute_names],
          :cols => Aux.array_add?(cols,field_to_match)
        }
        get_children_from_sp_hash(:attribute,sp_hash)
      end

      #attribute on component on node
      #assumption is that component cannot appear more than once on node
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

      ################
      #TODO: may be aqble to deprecate most or all of below
      ### helpers
      def ds_attributes(attr_list)
        [:ds_attributes]
      end
      #TODO: rename subobject to sub_object
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
