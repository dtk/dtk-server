module XYZ
  class ComponentOrder < Model
    def self.get_applicable_dependencies(component_idhs)
      sample_idh = component_idhs.first
      cols_for_get_virtual_attrs_call = [:component_type,:implementation_id,:extended_base]
      sp_hash = {
        :cols => [:id,:component_order_objs]+cols_for_get_virtual_attrs_call,
        :filter => [:oneof, :id, component_idhs.map{|idh|idh.get_id()}]
      }
      cmps_with_order_info = prune_if_not_applicable(get_objs(sample_idh.createMH,sp_hash))
      #cmps_with_order_info can have a component appear multiple fo each order relation
      dependency_form(cmps_with_order_info)
    end
   private
    def self.prune_if_not_applicable(cmps_with_order_info)
      ret = Array.new
      return ret if cmps_with_order_info.empty?
      with_conditionals = Array.new
      cmps_with_order_info.each do |cmp|
        order_info = cmp[:component_order]
        if order_info[:conditional]
          with_conditionals << cmp
        else
          ret << cmp
        end
      end
      with_conditionals.empty? ? ret : (prune(with_conditionals) + ret)
    end

    def self.prune(cmps_with_order_info)
      #TODO: stub that just treats very specific form
      #assuming conditional of form :":attribute_value"=>[":eq", ":attribute.<var>", <val>]
      attrs_to_get = Hash.new 
      cmps_with_order_info.each do |cmp|
        unexepected_form = true
        cnd = cmp[:component_order][:conditional]
        if cnd.kind_of?(Hash) and cnd.keys.first.to_s == ":attribute_value"
          eq_stmt =  cnd.values.first
          if eq_stmt.kind_of?(Array) and eq_stmt[0] == ":eq"
            if cnd.values.first[1] =~ /:attribute\.(.+$)/ and eq_stmt[2]
              attr_name = $1
              val = eq_stmt[2]
              unexepected_form = false
              match_cond = [:eq,:attribute_value,val]
              pntr = attrs_to_get[cmp[:id]] ||= {:component => cmp, :attr_info => Array.new} 
              pntr[:attr_info] << {:attr_name => attr_name, :match_cond => match_cond, :component_order => cmp[:component_order]}
            end
          end
        end
        raise Error.new("Unexpected form") if unexepected_form
      end
      ret = Array.new
      #TODO: more efficienct is getting this in bulk
      attrs_to_get.each do |cmp_id,info|
        info[:attr_info].each do |attr_info|
          #if component order appears twice then taht means disjunction
          next unless  attr_val_info = info[:component].get_virtual_attribute(attr_info[:attr_name],[:attribute_value])
          #TODO: stubbed form treating
          match_cond = attr_info[:match_cond]
          raise Error.new("Unexpected form") unless match_cond.size == 3 and match_cond[0] == :eq and match_cond[1] == :attribute_value
          if attr_val_info[:attribute_value] == match_cond[2]
            ret << info[:component].merge(:component_order => attr_info[:component_order]) 
          end
        end
      end
      ret
    end
  end
end


