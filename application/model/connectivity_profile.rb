module XYZ
  class ConnectivityProfile < ArrayObject
    #TODO: both args not needed if update the type hierarchy with leaf components 
    def self.find(cmp_type_x,most_specific_type_x,conn_type = :external)
      ret = self.new()
      cmp_type = cmp_type_x && cmp_type_x.to_sym
      most_specific_type = most_specific_type_x && most_specific_type_x.to_sym
      rules = get_possible_component_connections()
      ret_array = rules.map do |rule_input_cmp_type,rest|
        component_type_match(cmp_type,most_specific_type,rule_input_cmp_type) ? rest.merge(:input_component_type => rule_input_cmp_type) : nil
      end.compact
      self.new(ret_array)
    end

    def match_output(cmp_type_x,most_specific_type_x)
      ret = nil
      cmp_type = cmp_type_x && cmp_type_x.to_sym
      most_specific_type = most_specific_type_x && most_specific_type_x.to_sym
      self.each do |one_match|
        (one_match[:output_components]||[]).each do |output_info|
          rule_output_cmp_type = output_info.keys.first
          next unless self.class.component_type_match(cmp_type,most_specific_type,rule_output_cmp_type)
          #TODO: not looking for multiple matches and just looking fro first one
          ret = Aux::hash_subset(one_match,[:input_component_type,:required,:connection_type]).merge(:output_component_type => rule_output_cmp_type)
          info = output_info.values.first
          ams = info[:attribute_mappings]
          ret.merge!(ams ? info.merge(:attribute_mappings => ams.map{|x|AttributeMapping.new(x)}) : info)
          break
        end
        break if ret
      end
      ret
    end

   private
    def self.component_type_match(cmp_type,most_specific_type,rule_cmp_type)
      return true if (cmp_type == rule_cmp_type or most_specific_type == rule_cmp_type)
      type_class = ComponentType.ret_class(rule_cmp_type)
      type_class and type_class.include?(most_specific_type)
    end
    def self.get_possible_component_connections()
      @possible_connections ||= XYZ::PossibleComponentConnections #TODO: stub
    end
  end

  class AttributeMapping < HashObject
    def reset!(input_component,output_component)
      self[:processed_paths] = {
        :input => Aux::deep_copy(self[:input]),
        :output => Aux::deep_copy(self[:output])
      }
      self[:input_component] = input_component
      self[:output_component] = output_component
      self[:switched] = false
    end

    def create_new_components!()
      #TODO: for efficiency can do input and output at same time
      [:input,:output].each{|dir|create_new_components_aux!(dir)}
    end

    def get_attribute(dir)
      component,path = get_component_and_path(dir)
      #TODO: hard coded for certain cases; generalize to follow path which would be done by dynmaically generating join
      if path.size == 1 and not is_special_key?(path.first)
        component.get_virtual_attribute(path.first.to_s,[:id],:display_name)
      elsif path.size == 3 and is_special_key_type?(:parent,path.first)
        node = create_node_object(component)
        node.get_virtual_component_attribute({:component_type => path[1].to_s},{:display_name => path[2].to_s},[:id])
      elsif path.size == 2 and is_create_info?(path.first)
        cmp_id = is_create_info?(path.first)[:id]
        unless cmp_id
          Log.error("cannot find the id of new object created")
          return nil
        end
        node = create_node_object(component)
        node.get_virtual_component_attribute({:id => cmp_id},{:display_name => path[1].to_s},[:id])
      else
        raise Error.new("Not implemented yet")
      end
    end

   private
    def input_component()
      self[:input_component]
    end
    def output_component()
      self[:output_component]
    end
    def is_switched?()
      self[:switched]
    end
    def switch_input_and_output!()
      self[:switched] = true
    end

    def create_new_components_aux!(dir)
      component,path = get_component_and_path(dir)
      #TODO: hard wiring where we are looking for create not for example handling case where path starts with :parent
      create_info = is_create_info?(path.first)
      return unless create_info
      relation_name = create_info[:relation_name].to_s
      #find related component
      related_component = component.get_related_library_component(relation_name)
      raise Error.log("cannot find component that is related to #{component[:display_name]||"a component"} using #{relation_name}") unless related_component
      #clone related component into node that component is conatined in
      node = create_node_object(component)
      new_cmp_id = node.clone_into(related_component.id_handle())
      update_create_path_element!(path.first,new_cmp_id)
    end

    def create_node_object(component)
      component.id_handle.createIDH(:model_name => :node, :id => component[:node_node_id]).create_object()
    end

    #returns [component,path]; dups path so it can be safely modified
    def get_component_and_path(dir)
      path = self[:processed_paths][dir]
      component = nil
      reverse = (dir == :input) ? :output_component : :input_component
      if is_special_key_type?(reverse,path.first)
        path.shift
        if is_switched?() 
          component = (dir == :input) ? input_component : output_component
        else
          component = (dir == :output) ? input_component : output_component
          switch_input_and_output!()
        end
      else
        if is_switched?()
          component = (dir == :output) ? input_component : output_component
        else
          component = (dir == :input) ? input_component : output_component
        end
      end
      [component,path]
    end

    ###parsing functions and related functions
    def is_special_key?(item)
      (item.kind_of?(String) or item.kind_of?(Symbol)) and item.to_s =~ /^__/
    end
    def is_special_key_type?(type_or_types,item)
      types = Array(type_or_types)
      item.respond_to?(:to_sym) and types.map{|t|"__#{t}"}.include?(item.to_s)
    end
    
    #if item signifies to create a related component, this returns tenh relation name
    def is_create_info?(item)
      (item.kind_of?(Hash) and item.keys.first.to_s == "create") ? item.values.first : nil
    end
    def update_create_path_element!(item,id)
      item[:create].merge!(:id => id)
    end
  end
end
