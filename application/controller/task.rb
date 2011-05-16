module XYZ
  class TaskController < Controller
    def get_logs(level="info",task_id=nil)
      
      #task_id is nil means get most recent task
      #TODO: hack
      level = "info" if level == "undefined"
      level = level.to_sym

      model_handle = ModelHandle.new(ret_session_context_id(),model_name)

      unless task_id
        tasks = Task.get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
        task = tasks.first
      else
        raise Error.new("not implemented yet get_logs with task id given")
      end
      assoc_nodes = task.get_associated_nodes()

      parsed_log = nil
      found_error = nil
      if R8::Config[:command_and_control][:node_config][:type] == "mcollective"
        logs = CommandAndControl.get_logs(task,assoc_nodes)
      else
        logs = get_logs_mock(assoc_nodes)
      end

      #if multiple nodes present error otherwise present first
      #TODO: rather than working form hash look at marshal unmarshal functions
      first_parsed_log = nil
      logs.each do |node_id,result|
        pp "log for node_id #{node_id.to_s}"
        unless result[:data]
          pp "no log data"
          next
        end
        pl = ParseLog.parse(result[:data])
        first_parsed_log ||= pl
        STDOUT << pl.pp_form_summary
        #          File.open("/tmp/raw#{node_id.to_s}.txt","w"){|f|result[:data].each{|l|f << l+"\n"}}
        pp [:file_asset_if_error,pl.ret_file_asset_if_error(model_handle)]
        STDOUT << "----------------\n"
        #TODO: hack whete find error node and if no error node first node
        if pl.find{|seg|seg.type == :error}
          parsed_log = pl
          found_error = true
          break
        end
      end
      parsed_log ||= first_parsed_log 

      view_type =  
        if parsed_log.nil? then :simple 
        elsif level == :summary then parsed_log.error_segment ? :error_detail : :simple
        else level 
      end
      tpl = find_template_for_view_type(view_type,parsed_log)
      {:content => tpl.render()}
    end
  private
    ChefLogView = {
      :debug => "task/chef_log_view",
      :info => "task/chef_log_view",
      :simple => "task/chef_log_view_simple",
      :error_detail => "task/chef_log_view_error_detail"
    }

    def find_template_for_view_type(view_type,parsed_log)
      ret = R8Tpl::TemplateR8.new(ChefLogView[view_type],user_context())
      case view_type
       when :simple
        msg = parsed_log.nil? ? "no results" : summary(parsed_log)[:line]
        ret.assign(:msg,msg)
       when :debug
        segments = parsed_log.select{|s|[:info,:debug].include?(s.type)}.map{|s|s.hash_form()}
        segments << summary(parsed_log)
        ret.assign(:log_segments,segments)
       when :info
        segments = parsed_log.select{|s|[:info].include?(s.type)}.map{|s|s.hash_form()}
        segments << summary(parsed_log)
        ret.assign(:log_segments,segments)
       when :error_detail
        hash_form = parsed_log.error_segment.hash_form()
        [:error_detail,:error_lines].each do |val|
          ret.assign(val,hash_form[val])
        end
      end
      ret
    end

    def summary(log_segments)
      summary = 
        if log_segments.is_complete?() then log_segments.has_error?() ? "complete with error" : "complete and ok"
        elsif log_segments.has_error?() then "inomplete with error"
        else "inomplete no error yet"
        end
      {:type => "summary",
        :line => summary,
        :aux_data => []
      }
    end

    def get_logs_mock(assoc_nodes)
      ret = Hash.new
      i = 0
      assoc_nodes.each do |node|
        pp "log for node_id #{node[:id].to_s}"
        file = File.expand_path(SampleSets[i], File.dirname(__FILE__))
        raw_log = File.open(file){|f|f.read}
        data = Array.new
        raw_log.each_line{|l|data << l.chomp}
        ret[node[:id]] = {
          :data => data
        }
        i += i
        break if i >= SampleSets.size
      end
      ret
    end
    SampleSets = ["temp/error_example1.raw.txt"]
  end
end
