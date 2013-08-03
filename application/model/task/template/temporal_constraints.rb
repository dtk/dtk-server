module DTK; class Task; 
  class Template
    class TemporalConstraints < Array
      r8_nested_require('temporal_constraints','config_components')
      def indexes_in_stages()
        before_index_hash = create_before_index_hash()
        pp [:tsort_input,before_index_hash.tsort_form()]
      end

      def +(temporal_contraints)
        ret = self.class.new(self)
        temporal_contraints.each{|a|ret << a}
        ret
      end
     private
      def initialize(array=nil)
        super()
        array.each{|a|self << a} if array
        @after_relation = nil
      end

      def create_before_index_hash()
        ret = BeforeIndexHash.new()
        each{|constraint|ret.add(constraint.after_action_index,constraint.before_action_index)}
        ret
      end

      class BeforeIndexHash < Hash
        def add(after_action_index,before_action_index)
          (self[after_action_index] ||= Hash.new)[before_action_index] = true
        end
        
        def tsort_form()
          inject(Hash.new) do |h,(after_index,index_info)|
            h.merge(after_index => index_info.keys)
          end
        end
      end
    end
end; end; end

