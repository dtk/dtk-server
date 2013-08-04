module DTK; class Task; 
  class Template
    class TemporalConstraints < Array
      r8_nested_require('temporal_constraints','config_components')
      def indexes_in_stages(action_list)
        ret = Array.new
        return ret if action_list.empty?

        before_index_hash = create_before_index_hash(action_list)
        pp [:tsort_input,before_index_hash.tsort_form()]
        done = false
        while not done do
          if before_index_hash.empty?
            done = true
          else
            stage = before_index_hash.ret_and_remove_actions_not_after_any!()
            if stage.empty?()
              #TODO: see if any other way there can be loops
              raise ErrorUsage.new("Loop detected in temporal orders")
            end
            ret << stage
          end
        end
        ret
      end

      def +(temporal_contraints)
        ret = self.class.new(self)
        temporal_contraints.each{|a|ret << a}
        ret
      end
      def select(&body)
        ret = self.class.new()
        each{|r|ret << r if body.call(r)}
        ret
      end

     private
      def initialize(array=nil)
        super()
        array.each{|a|self << a} if array
        @after_relation = nil
      end

      def create_before_index_hash(action_list)
        ret = BeforeIndexHash.new(action_list.map{|a|a.index})
        each{|constraint|ret.add(constraint.after_action_index,constraint.before_action_index)}
        ret
      end

      class BeforeIndexHash < Hash
        def initialize(action_indexes)
          super()
          action_indexes.each{|action_index|self[action_index] = Hash.new}
        end

        def add(after_action_index,before_action_index)
          self[after_action_index][before_action_index] = true
        end
        
        def tsort_form()
          inject(Hash.new) do |h,(after_index,index_info)|
            h.merge(after_index => index_info.keys)
          end
        end

        def ret_and_remove_actions_not_after_any!()
          ret = Array.new
          each_key do |action_index|
            if self[action_index].empty?
              delete(action_index)
              ret << action_index
            end
          end
          #for all indexes in ret, remove them in the before hash
          each_value do |before_hash|
            before_hash.each_key do |before_action_instance|
              if ret.include?(before_action_instance)
                before_hash.delete(before_action_instance)
              end
            end
          end

          ret
        end
      end
    end
end; end; end

