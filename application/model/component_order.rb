module XYZ
  class ComponentOrder < Model
    def self.get_applicable_dependencies(component_idhs)
      sample_idh = component_idhs.first
      sp_hash = {
        :cols => [:id,:component_order_objs],
        :filter => [:oneof, :id, component_idhs.map{|idh|idh.get_id()}]
      }
      cmp_order_objs = get_objs(sample_idh.createMH,sp_hash).map{|r|r[:component_order]}
      prune_if_not_applicable(cmp_order_objs)
    end
   private
    def self.prune_if_not_applicable(cmp_order_objs)
      ret = Array.new
      return ret if cmp_order_objs.empty?
      with_conditionals = Array.new
      cmp_order_objs.each do |obj|
        if obj[:conditional]
          with_conditionals << obj
        else
          ret << obj
        end
      end
      return ret if with_conditionals.empty?

      #TODO: stub that just treats very specific form
      #assuming conditional of form :":attribute_value"=>[":eq", ":attribute.<var>", <val>]
      assigns = Array.new
      with_conditionals.each do |obj|
        unexepected_form = true
        cnd = obj[:conditional]
        if cnd.kind_of?(Hash) and cnd.keys.first.to_s == ":attribute_value"
          eq_stmt =  cnd.values.first
          if eq_stmt.kind_of?(Array) and eq_stmt[0] == ":eq"
            if cnd.values.first[1] =~ /:attribute\.(.+$)/ and eq_stmt[2]
              var = $1
              unexepected_form = false
              assigns << {:component_id => obj[:component_component_id], :var => var, :val => eq_stmt[2]}
            end
          end
        end
        Error.new("Unexpected form") if unexepected_form
      end
      ret
    end
  end
end


