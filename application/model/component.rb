require File.expand_path('model',  File.dirname(__FILE__))

module XYZ
  class Component < Model
    set_relation_name(:component,:component)
    class << self
      def up()
        has_ancestor_field()
        foreign_key :component_def_id, :component_def, FK_CASCADE_OPT
        many_to_one :component,:library,:deployment,:project
        one_to_many :component, :attribute_link, :attribute
        virtual_column :external_cmp_ref
      end

      ##### Actions

      #links component -> component_def and its attributes to their attribute defs
      def link_component_to_def(cmp_id_handle,cmp_def_id_handle)
        #No error checking because assumed called in a very limited context

	cmp_def_id = get_row_from_id_handle(cmp_def_id_handle)[:id]

	update_instance(cmp_id_handle,{:component_def_id => cmp_def_id}) 

	attr_fctr_id_handle = get_factory_id_handle(cmp_id_handle,:attribute)
        cmp_def_attrs = get_instance_or_factory(get_factory_id_handle(cmp_def_id_handle,:attribute_def))
        cmp_def_attrs.each_pair{|attr_ref,values|
          #find corresponding attr and attr_def; assumption is that can't have attr and attr-2 (a second
          #instance); so match on ref name
          attr_id_handle = get_child_id_handle_from_qualified_ref(attr_fctr_id_handle,attr_ref)
	  update_instance(attr_id_handle,:attribute_def_id => values[:id])     
        }
      end
    end
    def get_contained_attribute_ids(opts={})
      nested_cmps = self.class.get_objects_wrt_parent(:component,id_handle)
      (get_directly_contained_object_ids(:attribute)||[]) +
      (nested_cmps||[]).map{|cmp|cmp.get_contained_attribute_ids(opts)}.flatten()
    end

    #type can be :asserted, :derived or :value
    def get_contained_attribute_values(type,opts={})
      nested_cmps = self.class.get_objects_wrt_parent(:component,id_handle)
      ret = {}
      (nested_cmps||[]).each{|cmp|
	values = cmp.get_contained_attribute_values(type,opts)
	if values
	  ret[:component] ||= {}
          ret[:component][cmp.get_qualified_ref.to_sym] = values
        end
      }
      dir_vals = get_direct_attribute_values(type,opts)
      ret[:attribute] = dir_vals if dir_vals
      ret
    end

    def get_direct_attribute_values(type,opts={})
      attr_val_array = self.class.get_objects_wrt_parent(:attribute,id_handle)
      return nil if attr_val_array.nil?
      return nil if attr_val_array.empty?
      ret = {}
      attr_type = {:asserted => :value_asserted, :derived => :value_derived, :value => :attribute_value}[type]
      attr_val_array.each{|attr|
        v = {:value => attr[attr_type],:id => attr[:id]}
        opts[:attr_include].each{|a|v[a]=attr[a]} if opts[:attr_include]
        ret[attr.get_qualified_ref.to_sym] = v
      }
      ret
    end

    def get_objects_associated_nodes()
      assocs = Object.get_objects(:assoc_node_component,@c,:component_id => self[:id])
      return [] if assocs.nil?
      assocs.map{|assoc|Object.get_object(IDHandle[:c=>@c,:guid => assoc[:node_id]])}
    end

   private
     ### virtual column defs
    def external_cmp_ref()
      cmp_def = get_object_component_def()
      cmp_def ? cmp_def[:external_cmp_ref] : nil
    end

    def get_object_component_def()
      return nil if self[:component_def_id].nil?
      guid = IDInfoTable.ret_guid_from_db_id(self[:component_def_id],:component_def)
      Object.get_object(IDHandle[:c => id_handle[:c], :guid => guid])
    end
  end
end

module XYZ
  class ComponentDef < Model
    set_relation_name(:component,:component_def)
    class << self
      def up()
        column :external_type, :text
        column :external_cmp_ref, :text
        column :uri, :text
        many_to_one :library
	one_to_many :attribute_def
      end
    end
  end
end
