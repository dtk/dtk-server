require File.expand_path('model',  File.dirname(__FILE__))

module XYZ
  class Component < Model
    set_relation_name(:component,:component)
    class << self
      def up()
        has_ancestor_field()
        column :ds_attributes, :json
        column :ds_key, :varchar
        column :external_type, :varchar
        column :external_cmp_ref, :varchar
        column :uri, :varchar
        many_to_one :component,:library,:project
        one_to_many :component, :attribute_link, :attribute
      end
    end
    ##### Actions

    ###### Helper fns
    def get_contained_attribute_ids(opts={})
      nested_cmps = self.class.get_objects_wrt_parent(:component,id_handle)
      (get_directly_contained_object_ids(:attribute)||[]) +
      (nested_cmps||[]).map{|cmp|cmp.get_contained_attribute_ids(opts)}.flatten()
    end

    #type can be :asserted, :derived or :value
    def get_contained_attribute_values(type,opts={})
      nested_cmps = self.class.get_objects_wrt_parent(:component,id_handle)
      ret = Hash.new
      (nested_cmps||[]).each do |cmp|
	values = cmp.get_contained_attribute_values(type,opts)
	if values
	  ret[:component] ||= Hash.new
          ret[:component][cmp.get_qualified_ref.to_sym] = values
        end
      end
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
      attr_val_array.each do |attr|
        v = {:value => attr[attr_type],:id => attr[:id]}
        opts[:attr_include].each{|a|v[a]=attr[a]} if opts[:attr_include]
        ret[attr.get_qualified_ref.to_sym] = v
      end
      ret
    end

    def get_objects_associated_nodes()
      assocs = Object.get_objects(:assoc_node_component,@c,:component_id => self[:id])
      return Array.new if assocs.nil?
      assocs.map{|assoc|Object.get_object(IDHandle[:c=>@c,:guid => assoc[:node_id]])}
    end
  end
end

