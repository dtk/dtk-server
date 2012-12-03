module XYZ
  module AttributeGuardClassMixin
    def ret_attribute_guards(top_level_task)
      ret = Array.new
      augmented_attr_list = augmented_attribute_list_from_task(top_level_task)
      #augmented_attr_list does not contain node level attributes => attr_out can be null
      dependency_analysis(augmented_attr_list) do |attr_in,link,attr_out|
        if guard = GuardedAttribute.create(attr_in,link,attr_out)
          ret << guard
        end
      end
      ret
    end

    def ret_attr_guards_and_violations(top_level_task)
      guards = Array.new
      #augmented_attr_list does not contain node level attributes => attr_out can be null
      augmented_attr_list = augmented_attribute_list_from_task(top_level_task,:include_node_attributes => true)
      dependency_analysis(augmented_attr_list) do |attr_in,link,attr_out|
        if guard = GuardedAttribute.create(attr_in,link,attr_out)
          guards << guard
        end
      end
      attr_violations = ret_required_attrs_without_values(augmented_attr_list,guards)
      [guards,attr_violations]
    end
   private
    def ret_required_attrs_without_values(augmented_attr_list,guards)
      guarded_ids = nil
      violations = Array.new
      augmented_attr_list.each do |aug_attr|
        if aug_attr[:required] and aug_attr[:attribute_value].nil? 
          guarded_ids ||= guards.map{|g|g[:guarded][:attribute][:id]}.uniq
          unless guarded_ids.include?(aug_attr[:id])
           violations << Violation::MissingRequiredAttribute.new(aug_attr)
          end
        end
      end
      violations.empty? ? nil : Violation::ErrorViolations.new(violations)
    end
  end

  class GuardedAttribute < HashObject
    def self.create(guarded_attr,link,guard_attr)
      #guard_attr can be null if guard refers to node level attr
      #TODO: are there any other cases where it can be null; previous text said 'this can happen if guard attribute is in component that ran already'
      unless guard_attr 
        #TODO: below works if guard is node level attr
        return nil 
      end
      #guarding attributes that are unset and are feed by dynamic attribute 
      #TODO: should we assume that what gets here are only requierd attributes
      #TODO: removed clause (not guard_attr[:attribute_value]) in case has value that needs to be recomputed
      unless guard_attr[:dynamic] and unset_guarded_attr?(guarded_attr,link)
        return nil
      end

      #TODO: not sure if still needed
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

    #if dont know for certain better to err as being a guard
    def self.unset_guarded_attr?(guarded_attr,link)
      val = guarded_attr[:attribute_value]
      if val.nil?
        true
      elsif link[:function] == "array_append"
        unset_guarded_attr__array_append?(val,link)
      end
    end

    def self.unset_guarded_attr__array_append?(guarded_attr_val,link)
      if input_map = link[:index_map]
        unless input_map.size == 1
          raise Error.new("Not treating index map with more than one member")
        end
        input_index = input_map.first[:input]
        unless input_index.size == 1
          raise Error.new("Not treating input index with more than one member")
        end
        input_num = input_index.first
        unless input_num.kind_of?(Fixnum)
          raise Error.new("Not treating input index that is non-numeric")
        end
        guarded_attr_val.kind_of?(Array) and guarded_attr_val[input_num].nil?
      else
        true
      end
    end

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
        },
        :task_id => attr[:task_id]
      }
      return ret unless keys
      keys.inject({}){|h,(k,v)| keys.include?(k) ? h.merge(k => v) : h}
    end
  end
end
