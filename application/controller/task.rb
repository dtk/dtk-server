module XYZ
  class TaskController < Controller
    #TODO: test stub
    def rerun_components(node_id)
      node_idh = id_handle(node_id,:node)
      StateChange.create_rerun_state_changes([node_idh])
      {:content => nil}
    end

    #TODO: test stub
    def commit()
      model_handle = ModelHandle.new(ret_session_context_id(),:datacenter)
      datacenters = Model.get_objects_from_sp_hash(model_handle,{:cols =>[:id]})
      raise Error.new("only can be called when teher is one datacenter") unless datacenters.size == 1
      redirect "/xyz/workspace/commit_changes/#{datacenters.first[:id].to_s}"
    end


    def get_logs(task_id=nil)
      node_id = request.params["node_id"]
      node_id = node_id && node_id.to_i

      unless task_id
        tasks = Task.get_top_level_tasks(model_handle).sort{|a,b| b[:updated_at] <=> a[:updated_at]}
        task = tasks.first
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
      #put log in hash/array form
      hash_form =  logs_in_hash_form(parsed_logs,node_id.nil?)

#      stub_log = {2147535009=>
      stub_log = {node_id=>
  {:complete=>true,
   :log_segments=>
    [{:type=>:debug,
      :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] DEBUG: Building node object for domU-12-31-39-0C-76-77.compute-1.internal",
       :aux_data=>[]},
     {:type=>:debug,
      :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] DEBUG: Extracting run list from JSON attributes provided on command line",
      :aux_data=>[]},
      {:type=>:info,
      :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] INFO: Setting the run_list to [\"recipe[java_webapp]\"] from JSON",
      :aux_data=>[]},
     {:type=>:debug,
       :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] DEBUG: Applying attributes from json file",
      :aux_data=>[]},
     {:type=>:debug,
      :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] DEBUG: Platform is ubuntu version 10.04",
       :aux_data=>[]},
     {:type=>:info,
      :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] INFO: Run List is [recipe[java_webapp]]",
      :aux_data=>[]},
     {:type=>:info,
       :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] INFO: Run List expands to [java_webapp]",
      :aux_data=>[]},
     {:type=>:info,
      :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] INFO: Starting Chef Run for domU-12-31-39-0C-76-77.compute-1.internal",
       :aux_data=>[]},
     {:type=>:debug,
      :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] DEBUG: No chefignore file found at /var/chef/cookbooks/chefignore no files will be ignored",
       :aux_data=>[]},
     {:type=>:debug,
      :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] DEBUG: Node domU-12-31-39-0C-76-77.compute-1.internal loading cookbook java's attribute file /var/chef/cookbooks/java/attributes/default.rb",
       :aux_data=>[]},
     {:type=>:debug,
      :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] DEBUG: Loading Recipe java_webapp via include_recipe",
      :aux_data=>[]},
     {:type=>:debug,
       :line=>
       "[Fri, 17 Jun 2011 05:29:23 +0000] DEBUG: Found recipe default in cookbook java_webapp",
      :aux_data=>[]},
     {:type=>:error,
      :error_file_ref=>
       {:type=>:recipe, :cookbook=>"java_webapp", :file_name=>"default.rb"},
       :error_type=>:error_recipe,
      :error_line_num=>2,
      :error_lines=>[],
      :error_detail=>"syntax error, unexpected tEQQ, expecting $end"}],
   :summary=>
    {:type=>:error,
      :error_file_ref=>
      {:type=>:recipe, :cookbook=>"java_webapp", :file_name=>"default.rb"},
     :error_type=>:error_recipe,
     :error_line_num=>2,
     :error_lines=>[],
      :error_detail=>"syntax error, unexpected tEQQ, expecting $end"},
   :node_name=>"app"}}

      pp hash_form
      {:data => stub_log}
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
            #TODO: change hash form so do not have to reformulate
            pl = log_info[:parsed_log].hash_form
            log_segments = pl[:log_segments]
            error = nil
            if log_segments.last[:type] == :error 
              error = log_segments.last
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
      
      #task_id is nil means get most recent task
      #TODO: hack
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
        #TODO: do cases lower level
        #logs = task ? CommandAndControl.get_logs(task,assoc_nodes) : []
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
        #TODO: hack whete find error node and if no error node first node
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
        #just showing error cases
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
