module XYZ
  module AttributeGuardClassMixin
    def ret_attribute_guards(top_level_task)
      ret = Array.new
      augmented_attr_list = augmented_attribute_list_from_task(top_level_task)
      dependency_analysis(augmented_attr_list) do |match|
        if guard = ret_attribute_guard(augmented_attr_list,match)
          ret << guard
        end
      end
      ret
    end
   private
    def ret_attribute_guard(augmented_attr_list,match)
      link = match[:link]
      output_id =  link[:output_id] 
      matching_attr_out = augmented_attr_list.find{|attr| attr[:id] == output_id}
      if matching_attr_out
        debug_flag_unexpected_error(link)

        if matching_attr_out[:dynamic]
          ret_attribute_guard_aux(match[:attr],link,matching_attr_out)
        end
      else
        ret_attribute_guard_aux(match[:attr],link)
      end
    end

    def ret_attribute_guard_aux(guarded_attr,link,guard_attr=nil)
      #TODO: wil be used or leveraged when need guards
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
      task_guard
    end
  end
end
