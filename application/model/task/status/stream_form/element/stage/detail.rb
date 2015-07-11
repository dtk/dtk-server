module DTK; class Task::Status::StreamForm::Element
  class Stage
    class Detail
      def initialize(stage_elements)
        @elements = stage_elements
        @subtasks = nil
      end

      attr_reader :elements

      def self.add_detail!(stage_elements, hash_opts = {})
        new(stage_elements).add_detail!(Opts.new(hash_opts)).elements
      end
        
      def add_detail!(opts = Opts.new)
        ret = self
        return ret if @elements.empty?

        if opts.add_subtasks?
          add_subtasks!
          if opts.add_action_results?
            add_action_results!
          end
        end
        ret
      end

      private

      def add_subtasks!
        @subtasks = Array.new
        # TODO: stub
      end

      def add_action_results!
        if @subtasks.nil?
          raise Error.new("@subtasks should be set")
        end
        #TODO: stub
pp :add_action_results
      end

      class Opts < ::Hash
        def initialize(hash_opts = {})
          super()
          replace(hash_opts)
        end

        def add_subtasks?
          !([:action_results, :subtasks] & (detail().keys)).empty?
        end

        def add_action_results?
          detail().has_key?(:action_results)
        end

        private
          
        def detail
          self[:element_detail] || {}
        end
      end
    end
  end
end; end
