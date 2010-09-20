module XYZ
  class Component < Model
    set_relation_name(:component,:component)
    class << self
      def up()
        has_ancestor_field()
        column :type, :varchar, :size => 25 # instance | template | composite
        column :ds_attributes, :json, :hidden => true
        column :ds_key, :varchar, :hidden => true
        column :external_type, :varchar
        column :external_cmp_ref, :varchar
        column :uri, :varchar
        virtual_column :parent_name, :possible_parents => [:component,:library,:project]
        many_to_one :component,:library,:project
        one_to_many :component, :attribute_link, :attribute, :monitoring_item
      end
    end
    ##### Actions
    ### virtual column defs
    def parent_name()
      return "library/#{self[:library][:display_name]}" if self[:library] and self[:library][:display_name]
      return "project/#{self[:project][:display_name]}" if self[:project] and self[:project][:display_name]
      return "component/#{self[:component2][:display_name]}" if self[:component2] and self[:component2][:display_name]
      nil
    end
    ###### Helper fns
    def get_contained_attribute_ids(opts={})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      nested_cmps = get_objects(ModelHandle.new(id_handle[:c],:component),nil,:parent_id => parent_id)

      (get_directly_contained_object_ids(:attribute)||[]) +
      (nested_cmps||[]).map{|cmp|cmp.get_contained_attribute_ids(opts)}.flatten()
    end

    #type can be :asserted, :derived or :value
    def get_contained_attribute_values(type,opts={})
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      nested_cmps = get_objects(ModelHandle.new(id_handle[:c],:component),nil,:parent_id => parent_id)

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
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      attr_val_array = Model.get_objects(ModelHandle.new(c,:attribute),nil,:parent_id => parent_id)

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
      assocs = Model.get_objects(ModelHandle.new(@c,:assoc_node_component),:component_id => self[:id])
      return Array.new if assocs.nil?
      assocs.map{|assoc|Model.get_object(IDHandle[:c=>@c,:guid => assoc[:node_id]])}
    end
  end
end

