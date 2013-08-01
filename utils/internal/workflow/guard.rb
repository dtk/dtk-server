module DTK; class Workflow
  class Guard < SimpleHashObject
    def guards(top_level_task)
      Attribute.guards(top_level_task)
    end

   private
    class Attribute < self
      def self.guards(top_level_task)
        ret = Array.new
        augmented_attr_list = augmented_attribute_list_from_task(top_level_task)
        #augmented_attr_list does not contain node level attributes => attr_out can be null
        dependency_analysis(augmented_attr_list) do |attr_in,link,attr_out|
          if guard = create(attr_in,link,attr_out)
            ret << guard
          end
        end
        ret
      end

    private
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
        guard_task_type = (guard_attr[:semantic_type_summary] == "sap__l4" and (guard_attr[:item_path]||[]).include?(:host_address)) ? Task::Action::CreateNode : Task::Action::ConfigNode
        #right now only using config node to config node guards
        return nil if guard_task_type == Task::Action::CreateNode
        
        guard = {
          :task_type => guard_task_type
        }.merge(attr_info(guard_attr))
        
        guarded = {
          :task_type => Task::Action::ConfigNode
        }.merge(attr_info(guarded_attr))
        
        new(:guarded => guarded, :guard => guard, :link => link)
      end

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
end; end
