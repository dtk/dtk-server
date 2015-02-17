module DTK; class Task
  module QualifiedIndex
    Field = :qualified_index

    def self.string_form(task)
      convert_to_string_form(task[Field])
    end

    def self.compute!(subtask_indexes,top_task)
      compute_recursive!(subtask_indexes,top_task.id() => {})
    end
    
    private
    def self.convert_to_string_form(qualified_index)
      qualified_index  ? qualified_index.map{|r|r.to_s}.join(LabelIndexDelimeter) : ''
    end
    LabelIndexDelimeter = '.'

    # subtask_indexes hash form
    # {subtask_id => {:parent_id => ..., :index => ...}
    def self.compute_recursive!(subtask_indexes,parents)
      ret = Hash.new
      parent_ids = parents.keys
      subtask_indexes.each_pair do |subtask_id,info|
        if parent = parents[info[:parent_id]]
          subtask = subtask_indexes.delete(subtask_id)
          subtask[Field] = (parent[Field]||[]) + [subtask[:index]]
          ret.merge!(subtask_id => subtask)
        end
      end
      if ret.empty? or subtask_indexes.empty?
        ret
      else
        ret.merge(compute_recursive!(subtask_indexes,ret))
      end
    end
  end
end; end
