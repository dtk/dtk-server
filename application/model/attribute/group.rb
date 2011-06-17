module XYZ
  class AttrValType
    def self.create(type,attr)
      klass = AttrValTypeMap[type.to_sym]
      if klass then klass.new(type,attr)
      else raise Error.new("attribute value type (#{type}) not treated")
      end
    end

    #disjunction of types
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
      @is_set = attr[:attribute_value] ? true : false #TODO: handling legitimate nil values
    end
  end

  #TODO: if dont have type hierarchy then can simplify
  class AttrValTypeRequired < AttrValType
  end
  class AttrValTypeNotRequired < AttrValType
  end
  class AttrValTypeDynamic < AttrValType
  end
  class AttrValTypeLinked < AttrValType
  end

  AttrValTypeMap = {
    :required => AttrValTypeRequired,
    :not_required => AttrValTypeNotRequired,
    :dynamic => AttrValTypeDynamic,
    :linked => AttrValTypeLinked,
  }

  module AttributeGroupInstanceMixin
    def attribute_value_type()
      type = 
        if self[:dynamic] then :dynamic
        elsif self[:port_type] == "input" then :linked
        elsif self[:required] then :required
        else :not_required
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
      #find attributes that are required, but have no value
      selected_attrs = augmented_attr_list.select{|a|a[:required]}
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
        match[:attr].merge!(:port_type => "input")
        link = match[:link]
        output_id =  link[:output_id] 
        matching_attr_out = augmented_attr_list.find{|attr| attr[:id] == output_id}
        if matching_attr_out
          #TODO: handle if warning fires
          unless ["eq","select_one"].include?(link[:function]) or
              (link[:function] == "eq_indexed" and
               ((link[:index_map]||[]).first||{})[:output] == [])
            Log.error("can be error in treatment of matching output to link")
          end

          if matching_attr_out[:dynamic]
            add_task_guard__addr_for_config_node!(match[:attr],link,matching_attr_out)
          else
            matching_attr_out.merge!(:required => true)
          end
        else
          add_task_guard__addr_for_config_node!(match[:attr],link)
        end
      end
    end

    def add_task_guard__addr_for_config_node!(guarded_attr,link,guard_attr=nil)
      unless guard_attr
        #TODO: lock up the info
        guard_attr = {:node => "Need to compute"}
      end
      task_guard = {
        :condition => {
          :task_type => :create_node, 
          :node => guard_attr[:node]
        },
        :guarded_task => {
          :task_type => :config_node,
          :node => guarded_attr[:node]
        }
      }
      pp [:task_guard,task_guard]
    end

    def find_matching_link(attr,links)
      links.find{|link|link[:input_id] == attr[:id] and index_match(link,attr[:item_path])}
    end
    
    def index_match(link,item_path)
      ret = nil
      case link[:function]
       when "eq","select_one"
        ret = true
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
