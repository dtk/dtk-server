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

      chef_logging = nil
      if R8::Config[:command_and_control][:node_config][:type] == "mcollective"
        logs = CommandAndControl.get_logs(task,assoc_nodes)
        #if multiple nodes present error otherwise present first
        hash_form = nil
        logs.each do |node_id,result|
          pp "log for node_id #{node_id.to_s}"
          parsed_log = ParseLog.parse(result[:data])
          hash_form = parsed_log.hash_form()
          STDOUT << parsed_log.pp_form_summary
          pp [:file_asset_if_error,parsed_log.ret_file_asset_if_error(model_handle)]
          STDOUT << "----------------\n"
          break if hash_form[:log_segments].find{|seg|seg[:type] == :error}
        end
        if hash_form
          chef_logging = convert_symbols(hash_form)
        end
      else
        chef_logging = get_logs_mock(assoc_nodes)
      end

      chef_logging ||= get_logs_mock(assoc_nodes)

      tpl = R8Tpl::TemplateR8.new(ChefLogView[level],user_context())
      tpl.assign(:logging,filter_for_log_level(chef_logging,level))
      
      {:content => tpl.render()}
    end
  private

    ChefLogView = {
      :debug => "task/chef_log_view",
      :info => "task/chef_log_view",
      :summary => "task/chef_log_view"
    }

    def filter_for_log_level(chef_logging,level)
      segments = 
        case level
          when :debug then chef_logging["log_segments"] 
          when :info then chef_logging["log_segments"].select{|s|%w{info error}.include?(s["type"])}
          when :summary then [chef_logging["log_segments"].last]
      end
      chef_logging.merge("log_segments" => segments)
    end

    def convert_symbols(obj)
      if obj.kind_of?(Hash)
        obj.inject({}){|h,kv| h.merge(kv[0].to_s => convert_symbols(kv[1]))}
      elsif obj.kind_of?(Array)
        obj.map{|x|convert_symbols(x)}
      else
        obj
      end
    end
    def get_logs_mock(assoc_nodes)
      i = 0
      assoc_nodes.each do |node|
        pp "log for node_id #{node[:id].to_s}"
        file = File.expand_path(SampleSets[i], File.dirname(__FILE__))
        hash_form = File.open(file){|f|JSON.parse(f.read)}

        return hash_form

        i += i
        break if i >= SampleSets.size
      end
    end
    SampleSets = ["temp/error_example1.json","temp/ok_example1.json"]
  end
end
