module XYZ
  class ConnectivityProfile < ArrayObject
    #TODO: both args not needed if update the type hierarchy with leaf components 
    def self.find_external(cmp_type_x,most_specific_type_x)
      ret = nil
      cmp_type = cmp_type_x && cmp_type_x.to_sym
      most_specific_type = most_specific_type_x && most_specific_type_x.to_sym
      rules = get_possible_component_connections()
      ret_array = rules.map do |rule_input_cmp_type,rest|
        component_type_match(cmp_type,most_specific_type,rule_input_cmp_type) ? rest.merge(:input_component_type => rule_input_cmp_type) : nil
      end.compact
      ret_array.empty? ? nil : self.new(ret_array)
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

    #may collapse these with find external functions
    def self.find_internal(cmp_type_x,most_specific_type_x)
      ret = nil
      cmp_type = cmp_type_x && cmp_type_x.to_sym
      most_specific_type = most_specific_type_x && most_specific_type_x.to_sym
      rules = get_possible_intra_component_connections()
      ret_array = rules.map do |rule_cmp_type,rest|
        component_type_match(cmp_type,most_specific_type,rule_cmp_type) ? rest.merge(:matching_component_type => rule_cmp_type) : nil
      end.compact
      ret_array.empty? ? nil : self.new(ret_array)
    end

    def match_other_components(other_components)
      ret = Array.new
      other_components.each do |cmp|
        self.each do |one_match|
          match = self.class.match_other_components_aux(:input,cmp,one_match)
          ret << match if match
          match = self.class.match_other_components_aux(:output,cmp,one_match)
          ret << match if match
        end
      end
      ret
    end

   private
    def self.match_other_components_aux(dir,cmp,one_match)
      ret = nil
      cmp_type = cmp[:component_type]&& cmp[:component_type].to_sym
      most_specific_type = cmp[:most_specific_type] && cmp[:most_specific_type].to_sym
      to_merge = {:other_dir => dir}
      dir_index = (dir == :input) ? :input_components : :output_components
      (one_match[dir_index]||[]).each do |inside_info|
        rule_inside_cmp_type = inside_info.keys.first
        next unless component_type_match(cmp_type,most_specific_type,rule_inside_cmp_type)
        #TODO: not looking for multiple matches and just looking fro first one
        to_merge.merge!(:other_component => cmp,:other_component_type => rule_inside_cmp_type)
        ret = Aux::hash_subset(one_match,[:matching_component_type,:connection_type]).merge(to_merge)
        info = inside_info.values.first
        ams = info[:attribute_mappings]
        ret.merge!(ams ? info.merge(:attribute_mappings => ams.map{|x|AttributeMapping.new(x)}) : info)
        break
      end
      ret
    end


    def self.component_type_match(cmp_type,most_specific_type,rule_cmp_type)
      return true if (cmp_type == rule_cmp_type or most_specific_type == rule_cmp_type)
      type_class = ComponentType.ret_class(rule_cmp_type)
      type_class and type_class.include?(most_specific_type)
    end
    def self.get_possible_component_connections()
      @possible_connections ||= XYZ::PossibleComponentConnections #TODO: stub
    end

    def self.get_possible_intra_component_connections()
      return @possible_intra_connections if @possible_intra_connections #TODO: stub
      ret = PossibleIntraNodeConnections.dup 
      invert(ret).each do |k,v|
        if ret[k] then ret[k].merge!(k => v)
        else ret[k] = v
        end
      end      
      @possible_intra_connections = ret
    end

    def self.invert(x)
      ret = Hash.new
      x.each do |outside_cmp,v|
        dir = v[:input_components] ? :input_components : :output_components
        inv_dir = v[:output_components] ? :input_components : :output_components
        (v[dir]||[]).each do |cmp_info|
          inside_cmp = cmp_info.keys.first
          ret[inside_cmp] ||= Aux.hash_subset(v,v.keys-[dir]).merge(inv_dir => Array.new)
          ret[inside_cmp][inv_dir] << {outside_cmp => cmp_info.values.first}
        end
      end
      ret
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

    def ret_link()
      input_attr,input_path = get_attribute_with_unravel_path(:input)
      output_attr,output_path = get_attribute_with_unravel_path(:output)
      raise Error.new("cannot find input_id") unless input_attr
      raise Error.new("cannot find output_id") unless output_attr
      ret = {:input_id => input_attr[:id],:output_id => output_attr[:id]}
      ret.merge!(:input_path => input_path) if input_path
      ret.merge!(:output_path => output_path) if output_path
      ret
    end

   private

    #returns [attribute,unravel_path]
    def get_attribute_with_unravel_path(dir)
      ret_path = nil
      ret_attr = nil
      ret = [ret_attr,ret_path]
      component,path = get_component_and_path(dir)
      #TODO: hard coded for certain cases; generalize to follow path which would be done by dynmaically generating join
      if is_simple_key?(path.first)
        if path.size == 1
          ret_attr = component.get_virtual_attribute(path.first.to_s,[:id],:display_name)
        elsif is_unravel_path?(path[1..path.size-1])
          ret_attr = component.get_virtual_attribute(path.first.to_s,[:id],:display_name)
          ret_path = process_unravel_path(path[1..path.size-1],component)
        else
          raise Error.new("Not implemented yet")
        end
      elsif path.size == 3 and is_special_key_type?(:parent,path.first)
        node = create_node_object(component)
        ret_attr = node.get_virtual_component_attribute({:component_type => path[1].to_s},{:display_name => path[2].to_s},[:id])
      elsif path.size == 2 and is_create_component_info?(path.first)
        cmp_id = is_create_component_info?(path.first)[:id]
        unless cmp_id
          Log.error("cannot find the id of new object created")
          return ret
        end
        node = create_node_object(component)
        ret_attr = node.get_virtual_component_attribute({:id => cmp_id},{:display_name => path[1].to_s},[:id])
      else
        raise Error.new("Not implemented yet")
      end
      [ret_attr,AttributeLink::IndexMapPath.create_from_array(ret_path)]
    end

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
      create_info = is_create_component_info?(path.first)
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
    def is_simple_key?(item)
      (item.kind_of?(String) or item.kind_of?(Symbol)) and not item.to_s =~ /^__/
    end

    def is_special_key_type?(type_or_types,item)
      types = Array(type_or_types)
      item.respond_to?(:to_sym) and types.map{|t|"__#{t}"}.include?(item.to_s)
    end
    
    #if item signifies to create a related component, this returns tenh relation name
    def is_create_component_info?(item)
      (item.kind_of?(Hash) and item.keys.first.to_s == "create_component") ? item.values.first : nil
    end
    def update_create_path_element!(item,id)
      item[:create].merge!(:id => id)
    end

    def process_create_component_index(item,component)
      {:create_component_index => {:component_idh => component.id_handle()}}
    end

    def is_unravel_path?(path)
      path.each do |el|
        return false unless is_simple_key?(el) or is_special_key_type?(:create_component_index,el)
      end
      true
    end

    def process_unravel_path(path,component)
      path.map do |el|
        is_special_key_type?(:create_component_index,el) ? process_create_component_index(el,component) : el
      end
    end
  end
end
