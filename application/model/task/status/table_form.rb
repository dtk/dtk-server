module DTK
  class Task::Status
    module TableForm
      def self.status(task_structure,opts)
        task_structure.status_table_form(opts)
      end
      def self.format_errors(errors)
        ret = nil
        errors.each do |error|
          if ret
            ret[:message] << "\n\n"
          else
            ret = {:message => String.new}
          end
          
          if error.is_a? String
            error,temp = {},error
            error[:message] = temp
          end
          
          error_msg = (error[:component] ? "Component #{error[:component].gsub("__","::")}: " : "")
          error_msg << (error[:message]||"error")
          ret[:message] << error_msg
          ret[:type] = error[:type]
        end
        ret
      end
    end
  end
  class Task
    #TODO: may be cleaner to do this as mixin
    def status_table_form(opts,level=1,ndx_errors=nil)
      ret = Array.new
      set_and_return_types!()

      el = hash_subset(:started_at,:ended_at)
      el[:status] = self[:status] unless self[:status] == 'created'
      el[:id] = self[:id]
      type = element_type(level,self)
      # putting idents in
      el[:type] = "#{' '*(2*(level-1))}#{type}"
      ndx_errors ||= self.class.get_ndx_errors(hier_task_idhs())
      if ndx_errors[self[:id]]
        el[:errors] = Status::TableForm.format_errors(ndx_errors[self[:id]])
      end

      if level == 1
        # no op
      else
        ea = self[:executable_action]
        case self[:executable_action_type]
         when "ConfigNode" 
          el.merge!(Action::ConfigNode.status(ea,opts)) if ea
         when "CreateNode" 
          el.merge!(Action::CreateNode.status(ea,opts)) if ea
         when "PowerOnNode"
          el.merge!(Action::PowerOnNode.status(ea,opts)) if ea
         when "InstallAgent"
          el.merge!(Action::InstallAgent.status(ea,opts)) if ea
         when "ExecuteSmoketest"
          el.merge!(Action::ExecuteSmoketest.status(ea,opts)) if ea
        end
      end
      ret << el
      num_subtasks = subtasks.size
      # ret.add(self,:temporal_order) if num_subtasks > 1
      if num_subtasks > 0
        ret += subtasks.sort{|a,b| (a[:position]||0) <=> (b[:position]||0)}.map{|st|st.status_table_form(opts,level+1,ndx_errors)}.flatten(1)
      end
      ret
    end
    private
    def element_type(level,task)
      if level == 1
        self[:display_name] 
      elsif type = self[:type]
        if ['configure_node','create_node'].include?(type)
          if node = (self[:executable_action]||{})[:node]
            type = "#{type}group" if node.is_node_group?()
          end
        end
        type
      else
        self[:display_name]|| "top"
      end
    end
    private :element_type



 class Status
  module TableForm
