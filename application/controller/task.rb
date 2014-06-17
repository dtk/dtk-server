module XYZ
  class TaskController < AuthController
    helper :task_helper

    def rest__status()
      task_id,detail_level =  ret_request_params(:task_id,:detail_level)
      detail_level =  (detail_level||:summary).to_sym
      unless task_id
        # TODO: use Task.get_top_level_most_recent_task(model_handle,filter=nil)
        tasks = Task.get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
        task_id = tasks.first[:id]
      end
      opts = Task::Status::Opts.new
      if detail_level == :summary
        opts[:no_components] = true
        opts[:no_attributes] = true
      end

      task_structure = Task.get_hierarchical_structure(id_handle(task_id))
      state_info = task_structure.status_hash_form(opts)
      rest_ok_response state_info
    end

    def rest__create_task_from_pending_changes()
      scope_x = ret_request_params(:scope)||{}
      # TODO: put in check/error that there is no task created already, but not executed, that handles same changes

      # process raw scope
      scope = 
        if scope_x["target_ids"]
          # TODO: stub
        elsif scope_x["project_id"]
          sp_hash = {
            :cols => [:id],
            :filter => [:and, :project_project_id, scope_x["project_id"].to_i]
           }
          target_ids = Model.get_objs(model_handle(:target),sp_hash).map{|r|r[:id]}
          {:target_ids => target_ids}
        else
          # TODO: stub if scope by node_id
          Log.info("node_id scope given (#{scope_x["node_id"]})") if scope_x["node_id"]
          target_ids = Model.get_objs(model_handle(:target),{:cols => [:id]}).map{|r|r[:id]}
          {:target_ids => target_ids}
        end
      return Error.new("Only treating scope by target ids") unless target_scope = scope[:target_ids]
      return Error.new("Only treating scope given by single target") unless target_scope.size == 1

      target_idh = id_handle(target_scope.first,:target)
      pending_changes = StateChange.flat_list_pending_changes(target_idh)

      if pending_changes.empty?
        rest_notok_response :code => :no_pending_changes
      else
        task = Task.create_from_pending_changes(target_idh,pending_changes)
        task.save!()
        rest_ok_response :task_id => task.id
      end
    end

    def rest__execute()
      task_id =  ret_non_null_request_params(:task_id)
      task = Task.get_hierarchical_structure(id_handle(task_id))
      workflow = Workflow.create(task)
      workflow.defer_execution()
      rest_ok_response :task_id => task_id 
    end

    def rest__cancel_task()
      top_task_id = ret_non_null_request_params(:task_id)
      cancel_task(top_task_id)
      rest_ok_response :task_id => top_task_id
    end

    def rest__create_converge_state_changes()
      node_id = ret_request_params(:node_id)
      if node_id
        node_idhs = [id_handle(node_id,:node)]
      else
        # means get set of nodes
        # TODO: stub is to get all in target
        sp_hash = {
          :cols => [:id, :display_name],
          :filter => [:neq, :datacenter_datacenter_id, nil]
        }
        node_idhs = Model.get_objs(model_handle(:node),sp_hash).map{|r|r.id_handle}
      end
      StateChange.create_converge_state_changes(node_idhs)
      rest_ok_response
    end

###TODO temp for mocking
    @@count = 0
    def debug_mock_record(state_info)
      @@count += 1
      File.open("/tmp/save#{@@count.to_s}","w"){|f|f << JSON.pretty_generate(state_info)}
    end
    def debug_mock_replay()
      dir = File.expand_path('../spec/task_mock_data', File.dirname(__FILE__))
      Dir.chdir(dir) do
        save_files = Dir["*"]
        file = "save#{@@count.to_s}"
        file = save_files.sort.last unless save_files.include?(file)
        @@count += 1
        JSON.parse(File.open(file){|f|f.read})
      end
    end
### end temp for mocking

    # TODO: test stub
    def pretty_print(task_id=nil)
      unless task_id
        tasks = Task.get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
        task_id = tasks.first[:id]
      end
      top_task_idh = id_handle(task_id)
      task_structure = Task.get_hierarchical_structure(top_task_idh)
      pp_hash = task_structure.pretty_print_hash()
      pp pp_hash
      {:content => JSON.generate(pp_hash)}
    end


    def get_events(task_id=nil)
      unless task_id
        tasks = Task.get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
        task_id = tasks.first[:id]
      else
        raise Error.new("not implemented yet get_logs with task id given")
      end
      events = create_object_from_id(task_id).get_events
      pp events
      {:content => {}}
    end

    # TODO: templk hack
    def rest__get_logs()
      task_id = ret_request_params(:task_id) 
      # first time call can have no data because it is going to db and launching background call to nodes
      num_tries = 1
      max_tries = 5
      done = false
      while done or num_tries < max_tries do 
        data = get_logs(task_id)[:data]
        if data.values.find{|node_log| node_log[:summary] and node_log[:summary][:type] == "no_data"}
          sleep 0.5
          num_tries += 1
        else
          done = true
        end
      end
      data_reformulated = Array.new
      data.each do |node_id,info|
        # TODO: :complete is misleading
        info.delete(:complete)
        data_reformulated << info.merge(:node_id => node_id)
      end
      rest_ok_response data_reformulated
    end

    def get_logs(task_id=nil)
      node_id = request.params["node_id"]
      node_id = node_id && node_id.to_i

      unless task_id
        task = get_most_recent_task()
      else
        raise Error.new("not implemented yet get_logs with task id given")
      end

      assoc_nodes = ((task && task.get_associated_nodes())||[]).select{|n|node_id.nil? or n[:id] == node_id}
      ndx_node_names = assoc_nodes.inject({}){|h,n|h.merge(n[:id] => n[:display_name])}
      parsed_log = nil
      found_error = nil

      if R8::EnvironmentConfig::CommandAndControlMode == "mcollective"
        logs_info = task ? TaskLog.get_and_update_logs_content(task,assoc_nodes,:top_task_id => task.id()) : {}
      else
        logs_info = get_logs_mock(assoc_nodes).inject({}) do |h,(k,v)|
          h.merge(k => {:log => v, :type => "chef"})
        end
      end

      ####parse the logs
      parsed_logs = {:no_data =>  Array.new,:ok => Array.new, :error => Array.new}
      logs_info.each do |node_id,log_info|
        log = log_info[:log]
        node_name = ndx_node_names[node_id]
        unless log
          parsed_logs[:no_data] << {:node_id => node_id,:node_name => node_name}
          next
        end
        log_type = log_info[:type].to_sym
        pl = ParseLog.parse(log_type,log)
        type = pl.find{|seg|seg.type == :error} ? :error : :ok
        parsed_logs[type] << {:node_id => node_id, :node_name => node_name,:parsed_log => pl}
      end
      ### end parse logs
      # put log in hash/array form
      hash_form =  logs_in_hash_form(parsed_logs,node_id.nil?)

      #### fidning file id TODO: this shoudl be pushed to lower level
      hash_form.each do |k,v|
          el = (v[:log_segments]||[]).last || {}
          if efr=el[:error_file_ref]
          file = ret_file_asset(efr[:file_name],efr[:type],efr[:cookbook])
          efr[:file_id] = file[:id]
        end
      end

# TODO: temp hack so notice and err show for puppet logs
      if (logs_info.values.first||{})[:type] == "puppet"
        hash_form.each_value do |v|
          (v[:log_segments]||[]).each do |seg|
            if [:notice,:error].include?(seg[:type])
              seg[:type] = :debug
            end
          end
        end
      end

     {:data => hash_form}
    end

    def ret_file_asset(file_name,type,cookbook)
      file_asset_path = ret_file_asset_path(file_name,type)
      return nil unless file_asset_path and cookbook
      sp_hash = {
        :filter => [:eq, :path, file_asset_path],
        :cols => [:id,:path,:implementation_info]
      }
      file_asset_mh = model_handle.createMH(:file_asset)
      Model.get_objects_from_sp_hash(file_asset_mh,sp_hash).find{|x|x[:implementation][:repo] == cookbook}
    end

    def ret_file_asset_path(file_name,type)
      return nil unless file_name
      case type
      when :template
        # TODO: stub; since does not handle case where multiple versions
        "templates/default/#{file_name}"
      when :recipe
        "recipes/#{file_name}"
      end
    end

    def logs_in_hash_form(parsed_logs,is_single_node)
      ret = Hash.new
      parsed_logs.each do |type,logs|
        logs.each do |log_info|
          node_id = log_info[:node_id]
          node_name = log_info[:node_name]
          if type == :no_data
            ret[node_id] = {
              :node_name => node_name,
              :summary => {
                :type => :no_data
              }
            }
          else
            # TODO: change hash form so do not have to reformulate
            pl = log_info[:parsed_log].hash_form
            log_segments = pl[:log_segments]

            # TODO: see what other chars that need to be removed; once finalize move this to under hash_form
            log_segments = log_segments.map do |x|
              line = x[:line] && x[:line].gsub(/["]/,"")
              x.merge(:line => line)
            end

            error = nil
            if (log_segments.last||{})[:type] == :error 
              error = log_segments.last
pp [:log_error,error]
              # TODO: this looks like error; should be log_segments = log_segments[0..log_segments.size-2]
              log_segments = log_segments[1..log_segments.size-1]
            end
            summary = error ? error : {:type => :ok}
            ret[node_id] = {
              :node_name => node_name,
              :log_segments => log_segments,
              :complete => pl[:complete],
              :summary => summary
            }
          end
        end
      end
      is_single_node ? ret.values.first : ret
    end

    def get_logs_test(level="info",task_id=nil)
      
      # task_id is nil means get most recent task
      # TODO: hack
     # level = "info" if level == "undefined"
      level = "summary" if level == "undefined"
      level = level.to_sym

      unless task_id
        tasks = Task.get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
        task = tasks.first
      else
        raise Error.new("not implemented yet get_logs with task id given")
      end
      assoc_nodes = (task && task.get_associated_nodes())||[]
      ndx_node_names = assoc_nodes.inject({}){|h,n|h.merge(n[:id] => n[:display_name])}
      parsed_log = nil
      found_error = nil

#      if R8::Config[:command_and_control][:node_config][:type] == "mcollective"
      if R8::EnvironmentConfig::CommandAndControlMode == "mcollective"
        # TODO: do cases lower level
        # logs = task ? CommandAndControl.get_logs(task,assoc_nodes) : []
        logs_info = task ? TaskLog.get_and_update_logs_content(task,assoc_nodes,:top_task_id => task.id()) : {}
      else
        logs_info = get_logs_mock(assoc_nodes).inject({}) do |h,(k,v)|
          h.merge(k => {:log => v, :type => "chef"})
        end
      end

      ####parse the logs
      parsed_logs = {:no_data =>  Array.new,:ok => Array.new, :error => Array.new}
      logs_info.each do |node_id,log_info|
        log = log_info[:log]
        node_name = ndx_node_names[node_id]
        pp "log for node #{node_name} (id=#{node_id.to_s})"
        unless log
          pp "no log data"
          parsed_logs[:no_data] << {:node_id => node_id,:node_name => node_name}
          next
        end
        log_type = log_info[:type].to_sym
        pl = ParseLog.parse(log_type,log)
        ##STDOUT << pl.pp_form_summary
        #          File.open("/tmp/raw#{node_id.to_s}.txt","w"){|f|log.each{|l|f << l+"\n"}}
        ##pp [:file_asset_if_error,pl.ret_file_asset_if_error(model_handle)]
        ##STDOUT << "----------------\n"
        # TODO: hack whete find error node and if no error node first node
        type = pl.find{|seg|seg.type == :error} ? :error : :ok
        parsed_logs[type] << {:node_id => node_id, :node_name => node_name,:parsed_log => pl}
      end
      ### end parse logs

      view_type =  
        if no_results?(parsed_logs) then :simple 
        elsif level == :summary then parsed_logs[:error].empty? ? :simple : :error_detail 
        else level 
      end
      tpl = find_template_for_view_type(view_type,parsed_logs)
      {:content => tpl.render()}
    end
  private
    ChefLogView = {
      :debug => "task/chef_log_view",
      :info => "task/chef_log_view",
      :simple => "task/chef_log_view_simple",
      :error_detail => "task/chef_log_view_error_detail"
    }
    def no_results?(parsed_logs)
      not parsed_logs.values.find{|v|v.size > 0}
    end

    def each_parsed_log(parsed_logs,&block)
      [:no_data,:ok,:error].each do |type|
        parsed_logs[type].each do |el|
          node_info = "#{el[:node_name]} (id=#{el[:node_id].to_s})"
          block.call(type,node_info,el[:parsed_log])
        end
      end
    end
    def each_error_parsed_log(parsed_logs,&block)
      parsed_logs[:error].each do |el|
        node_info = "#{el[:node_name]} (id=#{el[:node_id].to_s})"
        block.call(node_info,el[:parsed_log])
      end
    end

    def find_template_for_view_type(view_type,parsed_logs)
      ret = R8Tpl::TemplateR8.new(ChefLogView[view_type],user_context())
      case view_type
       when :simple
        msgs = no_results?(parsed_logs) ? ["no results"] : summary(parsed_logs)
        ret.assign(:msgs,msgs)
       when :debug, :info
        pls = Array.new
        incl = view_type == :debug ? [:info,:debug] : [:info]
        each_parsed_log(parsed_logs) do |type,node_info,parsed_log|
          segments = (parsed_log||[]).select{|s|incl.include?(s.type)}.map{|s|s.hash_form()}
          pls << {:type => type,:node_info => node_info,:segments => segments}
        end
        ret.assign(:parsed_logs,pls)
       when :error_detail
        # just showing error cases
        errors = Array.new
        each_error_parsed_log(parsed_logs) do |node_info,parsed_log|
          hash_form = parsed_log.error_segment.hash_form()
          pp [:error_info,hash_form]
          err = [:error_detail,:error_lines].inject(:node_info => node_info) do |h,val|
            h.merge(val => hash_form[val])
          end
          errors << err
        end
        ret.assign(:errors,errors)
      end
      ret
    end

    def summary(parsed_logs)
      ret = Array.new
      each_parsed_log(parsed_logs) do |type,node_info,parsed_log|
        ret << "--------------- #{node_info} ----------------------"
        summary = 
          if type == :no_data then "no_data"
          elsif parsed_log.is_complete?() then type == :error ? "complete with error" : "complete and ok"
          elsif type == :error then "incomplete with error"
          else "incomplete no error yet"
          end
        ret << summary
        ret << "-------------------------------------------------------"
      end
      ret
    end

    def get_logs_mock(assoc_nodes)
      ret = Hash.new
      i = 0
      assoc_nodes.each do |node|
        pp "log for node_id #{node[:id].to_s}"
        file = File.expand_path(SampleSets[i], File.dirname(__FILE__))
        raw_log = File.open(file){|f|f.read}
        log = Array.new
        raw_log.each_line{|l|log << l.chomp}
        ret[node[:id]] = log
        i += i
        break if i >= SampleSets.size
      end
      ret
    end
    SampleSets = ["temp/error_example1.raw.txt"]
  end
end
