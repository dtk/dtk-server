module XYZ
  module AttributeGuardClassMixin
    def ret_attribute_guards(top_level_task)
      ret = Array.new
      augmented_attr_list = augmented_attribute_list_from_task(top_level_task)
      dependency_analysis(augmented_attr_list) do |attr_in,link,attr_out|
        if guard = ret_attribute_guard(attr_in,link,attr_out)
          ret << guard
        end
      end
      ret
    end
   private
    def ret_attribute_guard(guarded_attr,link,guard_attr=nil)
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
