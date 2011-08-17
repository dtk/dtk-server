module XYZ
  module AttributeGuardClassMixin
    def ret_attribute_guards(top_level_task)
      ret = Array.new
      augmented_attr_list = augmented_attribute_list_from_task(top_level_task)
      dependency_analysis(augmented_attr_list) do |attr_in,link,attr_out|
        if guard = GuardedAttribute.create(attr_in,link,attr_out)
          ret << guard
        end
      end
      ret
    end
  end
  class GuardedAttribute < HashObject
    def self.create(guarded_attr,link,guard_attr)
      #TODO: shouldnt this be error? or instaed if ran already than this attribute should be set
      unless guard_attr #this can happen if guard attribute is in component that ran already
        unless guarded_attr[:attribute_value]
          Log.error("unexpected: if guard_attr is null then guarded_attrib #{guarded_attr[:display_name]} should have a value set")
        end
        return nil 
      end
      #guarding attributes that are unset and 
      #TODO: should we assume that what gets here are only requierd attributes
      unless guard_attr[:dynamic] and (not guard_attr[:attribute_value]) and (not guarded_attr[:attribute_value])
        return nil
      end

      guard_task_type = (guard_attr[:semantic_type_summary] == "sap__l4" and (guard_attr[:item_path]||[]).include?(:host_address)) ? TaskAction::CreateNode : TaskAction::ConfigNode
      #right now only using config node to config node guards
      return nil if guard_task_type == TaskAction::CreateNode

      guard = {
        :task_type => guard_task_type
      }.merge(attr_info(guard_attr))

      guarded = {
        :task_type => TaskAction::ConfigNode
      }.merge(attr_info(guarded_attr))

      new(:guarded => guarded, :guard => guard, :link => link)
    end
   private
    def self.attr_info(attr,keys=nil)
      ret = {
        :node => {
          :id => attr[:node][:id],
          :display_name =>  attr[:node][:display_name]
        },
        :component => {
          :id => attr[:component][:id],
          :display_name =>  attr[:component][:display_name]
        },
        :attribute => {
          :id => attr[:id],
          :display_name =>  attr[:display_name]
        }
      }
      return ret unless keys
      keys.inject({}){|h,(k,v)| keys.include?(k) ? h.merge(k => v) : h}
    end
  end
end
