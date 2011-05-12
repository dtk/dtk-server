module XYZ
  class TaskController < Controller
    def get_logs(task_id=nil)
      #task_id is nil means get most recent task
      model_handle = ModelHandle.new(ret_session_context_id(),model_name)

      unless task_id
        tasks = Task.get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
        task = tasks.first
      else
        raise Error.new("not implemented yet get_logs with task id given")
      end
      assoc_nodes = task.get_associated_nodes()

      unless R8::Config[:command_and_control][:node_config][:type] == "mcollective"
        get_logs_mock(assoc_nodes)
        return {:content => {}}
      end

      logs = CommandAndControl.get_logs(task,assoc_nodes)
      pp "----------------"
      i = 0
      logs.each do |node_id,result|
        pp "log for node_id #{node_id.to_s}"
          parsed_log = ParseLog.parse(result[:data])
          hash_form = parsed_log.hash_form()
          #File.open("/tmp/t#{node_id.to_s}.json","w"){|f|f << JSON.pretty_generate(hash_form)}
          STDOUT << parsed_log.pp_form_summary
          pp [:file_asset_if_error,parsed_log.ret_file_asset_if_error(model_handle)]
          STDOUT << "----------------\n"
      end
      {:content => {}}
    end
  private
    def get_logs_mock(assoc_nodes)
      i = 0
      assoc_nodes.each do |node|
        pp "log for node_id #{node[:id].to_s}"
        file = File.expand_path(SampleSets[i], File.dirname(__FILE__))
        hash_form = File.open(file){|f|JSON.parse(f.read)}
        i += i
        break if i >= SampleSets.size
      end
    end
    SampleSets = ["temp/error_example1.json","temp/ok_example1.json"]
  end
end
