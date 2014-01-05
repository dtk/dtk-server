module DTK; class Task; class Template
  class Stage; class IntraNode
    class ExecutionBlock < Array
      include Serialization
      include DSLParsingAux
      def node()
        #all the elements have same node so can just pick first
        first && first[:node]
      end
      def config_agent_type()
        #TODO: for now all  elements have same config_agent_type, so can just pick first
        first && first.config_agent_type()
      end
      def components()
        map{|a|a.hash_subset(*Component::Instance.component_list_fields)}
      end

      def find_earliest_match?(action_match,action_indexes)
        each_action_with_position do |a,pos|
          if action_indexes.include?(a.index)
            action_match.action = a
            action_match.action_position = pos
            return true
          end
        end
        false
      end

      def delete_action!(action_match)
        delete_at(action_match.action_position()-1)
        :empty if empty?()
      end
       
      def splice_in_action!(action_match,insert_point)
        case insert_point
          when :end
            self << action_match.insert_action
          when :before_action_pos
            insert(action_match.action_position-1,action_match.insert_action)
          else raise Error.new("Unexpected insert_point (#{insert_point})")
        end
      end
        
      def serialization_form(opts={})
        items = Array.new
        component_group_num = 0
        component_group = nil
        each do |a|
          add_to_group = false
          if cgn = a.component_group_num
            Log.error('set add_to_group to true')
            if cgn == component_group_num 
              if item = a.serialization_form(opts)
               Log.error('add to component_group')
              end
            else
               Log.error('add component_group to items if not null; bump component_group_num; ..') 
            end
          end 

          if add_to_group
            if item = a.serialization_form(opts)
              items << item
            end
          end
        end
        if component_group
          items << component_group
        end
        {:ordered_components => items} unless items.empty?
      end

      #action list can be nil just for parsing
      def self.parse_and_reify(serialized_eb,node_name,action_list)
        ret = new()
        return ret unless action_list
        unless ordered_items = serialized_eb[:ordered_components]
          raise ErrorParsing.new("Ill-formed Execution block (#{serialized_eb.inspect})")
        end
        component_group_num = 1
        ordered_items.each do |serialized_item|
          lvs = LegalValues.new()
          if lvs.add_and_match?(serialized_item,String)
            find_and_add_action!(ret,serialized_item,node_name,action_list)
          elsif lvs.add_and_match?(serialized_item){HashWithKey(Constant::ComponentGroup)}
            component_group = serialized_item.values.first
            ErrorParsing.raise_error_unless(component_group,[String,Array])
            Array(component_group).each do |serialized_action|
              find_and_add_action!(ret,serialized_action,node_name,action_list,:component_group_num => component_group_num)
            end
            component_group_num += 1
          else
            raise ErrorParsing::WrongType.new(serialized_item,lvs)
          end
        end
        ret
      end

     private
      def self.find_and_add_action!(ret,serialized_item,node_name,action_list,opts={})
        component_name_ref = serialized_item
        if action = action_list.find_matching_action(node_name,component_name_ref)
          if cgn = opts[:component_group_num]
            action.component_group_num = cgn
          end
          ret << action
        else
          raise ErrorParsing.new("Component action ref (#{component_name_ref}) on node (#{node_name}) cannot be resolved")
        end        
      end

      def each_action_with_position(&block)
        each_with_index{|a,i|block.call(a,i+1)}
      end

      class Unordered < self
        def order(intra_node_contraints,strawman_order=nil)
          #short-cut, no ordering if singleton
          if size < 2
            return Ordered.new(self)
          end
          ret = Ordered.new()
          sorted_action_indexes = intra_node_contraints.ret_sorted_action_indexes(self)
          ndx_action_list = inject(Hash.new){|h,a|h.merge(a.index => a)}
          sorted_action_indexes.each{|index|ret << ndx_action_list[index]}
          ret
        end
      end
    
      class Ordered < self
        def initialize(array=nil)
          super()
          if array
            array.each{|el|self << el}
          end
        end
      end
    end

  end; end
end; end; end
