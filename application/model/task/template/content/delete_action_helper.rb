module DTK; class Task; class Template
  class Content
    class DeleteActionHelper
      def initialize(action,action_list)
        @action = action_list.find{|a|a.match_action?(action)}
      end

      def delete_explicit_action?(template_content)
        #call it 'explicit action' because action may be included as general rule', but nothing to delete 
        # @action can be null because it is found using 'action_list.find' in constructor
        if action_match = (@action && template_content.includes_action?(@action))
          unless action_match.in_multinode_stage
            delete_action!(template_content,action_match)
            template_content
          end
        end
      end
     private
      def delete_action!(template_content,action_match)
        raise ErrorUsage.new("need to write delete_action!") 
        #TODO: use action_match to fidn wheer to delete; added logic in case what you are deleting is last element in ordere action, execution block, execution blocks
        template_content
      end
    end
  end
end;end;end
