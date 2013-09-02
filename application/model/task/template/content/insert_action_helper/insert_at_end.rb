module DTK; class Task; class Template
  class Content
    class InsertActionHelper
      class InsertAtEnd < self
        def insert_action(template_content)
          template_content.each_internode_stage do |internode_stage,stage_index|
            if action_match = find_earliest_match?(internode_stage,stage_index,:internode,:after)
              #if match here then need to put in stage earlier than matched one
              template_content.splice_in_action!(action_match,:before_internode_stage)
              return
            end
            if action_match = find_earliest_match?(internode_stage,stage_index,:samenode,:after)
              #if match here then need to put in this stage earlier than matched one
              template_content.splice_in_action!(action_match,:before_action_pos)
              return
            end
          end
           action_match = ActionMatch.new(@new_action)
           template_content.splice_in_action!(action_match,:end_last_internode_stage)
        end
      end
        
      def find_earliest_match?(internode_stage,stage_index,inter_or_same,before_or_after)
        ndx_action_indexes = get_ndx_action_indexes(inter_or_same,before_or_after)
        return nil if ndx_action_indexes.empty?()
        action_match = ActionMatch.new(@new_action)
        if internode_stage.find_earliest_match?(action_match,ndx_action_indexes)
          action_match.internode_stage_index = stage_index
          action_match
        end
      end

    end
  end
end;end;end
