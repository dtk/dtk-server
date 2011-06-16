module XYZ
  class AttrValType
    def self.create(type,attr)
      klass = AttrValTypeMap[type.to_sym]
      if klass then klass.new(type,attr)
      else raise Error.new("attribute value type (#{type}) not treated")
      end
    end
    def type_of?(*types)
      types.find do |type|
        unless type_klass = AttrValTypeMap[type]
          Log.error("illegal type given #{type}")
          next
        end
        self.kind_of?(type_klass)
      end ? true : nil
    end
   private
    def initialize(type,attr)
      @type=type.to_sym
    end
  end

  class AttrValTypeSet < AttrValType
  end
  class AttrValTypeUnset < AttrValType
  end
  class AttrValTypeUnsetRequired < AttrValTypeUnset
  end
  class AttrValTypeUnsetDynamic < AttrValTypeUnset
  end
  class AttrValTypeUnsetLinked < AttrValTypeUnset
  end
  class AttrValTypeUnsetNotRequired < AttrValTypeUnset
  end

  AttrValTypeMap = {
    :set => AttrValTypeSet,
    :unset_required => AttrValTypeUnsetRequired,
    :unset_not_required => AttrValTypeUnsetNotRequired,
    :unset_dynamic => AttrValTypeUnsetDynamic,
    :unset_linked => AttrValTypeUnsetLinked,
  }

  module AttributeGroupInstanceMixin
    def attribute_value_type()
      #TODO: detecting legititamate null value
      #TODO: need way to propagate required on inputs to outputs 
      type = 
        if self[:attribute_value] then :set
        elsif self[:dynamic] then :unset_dynamic
        elsif self[:port_type] == "input" then :unset_linked
        elsif self[:required] then :unset_required
        else :unset_not_required
       end
      raise Error.new("Cannot detect type of attribute") unless type
      AttrValType.create(type,self)
    end
  end
  module AttributeGroupClassMixin
    #marjked with "!" because augments info
    def ret_grouped_attributes!(augmented_attr_list,opts={})
      prune_set = opts[:types_to_keep]
      add_missing_info_for_group_attrs!(augmented_attr_list,prune_set)

      ret = Array.new
      augmented_attr_list.each do |attr|
        type = attr.attribute_value_type()
        ret << attr.merge(:attr_val_type => type) if prune_set.nil? or type.type_of?(*prune_set)
      end
      ret
    end
    def augmented_attribute_list_from_task(task)
      component_actions = task.component_actions
      ret = Array.new 
      component_actions.each do |action|
        AttributeComplexType.flatten_attribute_list(action[:attributes],:flatten_nil_value=>true).each do |attr|
          ret << attr.merge(:component => action[:component], :node => action[:node])
        end
      end
      ret
    end
   private
    def add_missing_info_for_group_attrs!(augmented_attr_list,prune_set)
      #TODO: add input direction if not present
      #TODO: propagate back required
      #TODO: can make more efficient by calling this just once and storing info in attributes;
      #might put in some json attribute
      #need analysis that looks at the index maps

      #find attributes that are required, but have no value
      selected_attrs = augmented_attr_list.select{|a|a[:required] and a[:attribute_value].nil?}
      return if selected_attrs.empty?
      attr_ids = selected_attrs.map{|a|a[:id]}.uniq
      sp_hash = {
        :cols => [:function,:index_map,:input_id,:output_id],
        :filter => [:oneof ,:input_id, attr_ids]
      }
      sample_attr = selected_attrs.first
      attr_link_mh = sample_attr.model_handle(:attribute_link)
      links_to_trace = get_objects_from_sp_hash(attr_link_mh,sp_hash)
      
      matches = Array.new
      selected_attrs.each do |attr|
        link = find_matching_link(attr,links_to_trace)
        matches << {:link => link, :attr => attr} if link
      end
      matches.each do |match|
        link = match[:link]
        output_id =  link[:output_id] 
        matching_out = augmented_attr_list.find{|attr| attr[:id] == output_id}
        next unless matching_out

        #TODO: handle if warning fires
        unless link[:function] == "eq" or
               (link[:function] == "eq_indexed" and
                ((link[:index_map]||[]).first||{})[:output] == [])
          Log.error("can be error in treatment of matching output to link")
        end
        matching_out.merge!(:required => true)
        match[:attr].merge!(:port_type => "input")
      end
    end

    def find_matching_link(attr,links)
      links.find{|link|link[:input_id] == attr[:id] and index_match(link,attr[:item_path])}
    end
    
    def index_match(link,item_path)
      ret = nil
      case link[:function]
       when "eq" then true
       when "eq_indexed"
        if (link[:index_map]||[]).size > 1
          Log.error("not treating index maps with multiple elements")
        end
        if index_map = ((link[:index_map]||[]).first||{})[:input]
          if item_path.kind_of?(Array) and index_map.size == item_path.size
            item_path.each_with_index do |el,i|
              return nil unless el.to_s == index_map[i].to_s
            end
            ret = true
          end 
        end
      end
      ret
    end
  end
end
