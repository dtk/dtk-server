module DTK; class Task
  class Template
    class TemporalConstraints < Array
      r8_nested_require('temporal_constraints','config_components')

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

      def ret_sorted_action_indexes(action_list)
        before_index_hash = create_before_index_hash(action_list)
        before_index_hash.tsort_form.tsort()
      end
      # only uses a constraint if both members belong to action_list
      def create_before_index_hash(action_list)
        action_indexes =  action_list.map(&:index)
        ret = BeforeIndexHash.new(action_indexes)
        each do |constraint|
          after_action_index = constraint.after_action_index
          before_action_index = constraint.before_action_index
          if action_indexes.include?(after_action_index) && action_indexes.include?(before_action_index)
            ret.add(after_action_index,before_action_index)
          end
        end
        ret
      end

      private

      def initialize(array=nil)
        super()
        array.each{|a|self << a} if array
        @after_relation = nil
      end

      class BeforeIndexHash < Hash
        def initialize(action_indexes)
          super()
          action_indexes.each{|action_index|self[action_index] = {}}
        end

        def add(after_action_index,before_action_index)
          self[after_action_index][before_action_index] = true
        end

        def tsort_form
          inject(TSortHash.new) do |h,(after_index,index_info)|
            h.merge(after_index => index_info.keys)
          end
        end

        def ret_and_remove_actions_not_after_any!
          ret = []
          each_key do |action_index|
            if self[action_index].empty?
              delete(action_index)
              ret << action_index
            end
          end
          # for all indexes in ret, remove them in the before hash
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
  end
end; end
