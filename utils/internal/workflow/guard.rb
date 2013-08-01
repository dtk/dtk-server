module DTK; class Workflow
  class Guard < SimpleHashObject
    def self.ret_guards(top_level_task)
      ret = GuardedAttribute.ret_guards(top_level_task)
      if assembly = top_level_task.assembly()
        ret += AssemblyPortLinks.ret_guards(assembly)
      end
      ret
    end
    def internal_or_external()
      self[:guarded][:node][:id] ==  self[:guard][:node][:id] ? :internal : :external
    end

   private
    class Element < SimpleHashObject
      def initialize(node,component,task_id,other_vals={})
        el = {
          :node => node.hash_subset(:id,:display_name), 
          :component => component.hash_subset(:id,:display_name),
          :task_id => task_id
        }.merge(other_vals)
        el[:task_type] ||= Task::Action::ConfigNode
        super(el)
      end
    end

    class AssemblyPortLinks < self
      def self.ret_guards(assembly)
        #TODO: should share code with Stage::Internode.get_internode_dependencies__port_link_order(
        ret = Array.new
        #TODO: may want to filter to see if any assembly dependencies not in task
        ordered_port_links = assembly.get_port_links(:filter => [:neq,:temporal_order,nil])
        return ret if ordered_port_links.empty?
        sp_hash = {
          :cols => [:augmented_ports,:temporal_order],
          :filter => [:oneof, :id, ordered_port_links.map{|r|r.id}]
        }
        aug_port_links = Model.get_objs(assembly.model_handle(:port_link),sp_hash)
        pp aug_port_links
        raise Error,new("Got here; need to bring in task info and look at that to find component and node; node is not below")

        aug_port_links.map do |pl|
          before = DirIndex[pl[:temporal_order].to_sym][:before_index]
          after = DirIndex[pl[:temporal_order].to_sym][:after_index]
          #TODO: need to get task_id
          task_id = nil
          guard = Element.new(pl[before[:node]],pl[before[:cmp]],task_id)
          guarded = Element.new(pl[after[:node]],pl[after[:cmp]],task_id)
          new(:guarded => guarded, :guard => guard)
        end
      end
      InputKeys = {:node => :input_node, :cmp => :input_component}
      OutputKeys = {:node => :output_node, :cmp => :output_component}
      DirIndex = {
        :before => {:before_index => InputKeys,  :after_index => OutputKeys},  
        :after =>  {:before_index => OutputKeys, :after_index => InputKeys}
      }
    end

    class GuardedAttribute < self
      def self.ret_guards(top_level_task)
        ret = Array.new
        augmented_attr_list = Attribute.augmented_attribute_list_from_task(top_level_task)
        #augmented_attr_list does not contain node level attributes => attr_out can be null
        Attribute.dependency_analysis(augmented_attr_list) do |attr_in,link,attr_out|
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
        
        guard = element(guard_attr,guard_task_type)
        guarded = element(guarded_attr)
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

      def self.element(attr,task_type=nil)
        other_vals = {:attribute => attr.hash_subset(:id,:display_name)}
        other_vals[:task_type] = task_type if task_type
        Element.new(attr[:node],attr[:component],attr[:task_id],other_vals)
      end
    end
  end
end; end
