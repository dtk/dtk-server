#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class ExecuteOnNode < NodeParticipants
        def consume(workitem)
          params = get_params(workitem)
          PerformanceService.start("#{self.class.to_s.split('::').last}", self.object_id)
          task_id, action, workflow, task, task_start, task_end = %w(task_id action workflow task task_start task_end).map { |k| params[k] }
          top_task = workflow.top_task
          task.update_input_attributes!() if task_start
          breakpoint = task[:breakpoint]
          # DTK-3265 - Almin: refactor this
          task[:retry] = top_task[:retry].to_i unless top_task[:retry].empty? || top_task[:retry].nil?
          task[:attempts] = top_task[:attempts].to_i unless top_task[:attempts].empty? || top_task[:attempts].nil?
          task[:task_params] = top_task[:task_params] unless top_task[:task_params].nil? || top_task[:task_params].empty?
          # Almin, HACK: Consider Changing this.. 
          # Added because delete is making problems with :retry key, need to find where top_task is created and add key on subtasks objects instead of this fix
          top_task[:subtasks].each do |sub|
            sub[:subtasks].each do |st|
              if st.has_key?(:subtasks)
                st[:subtasks].each do |id|
                  if id.has_key?(:subtasks)
                    id[:subtasks].each do |i|
                      task[:retry] = st[:retry] if i[:id] == task[:id]
                    end
                  end
                end
              end
              if st[:id] == task[:id] && task[:retry] != 0
                task[:retry] = sub[:retry] unless sub[:retry].empty? || sub[:retry].nil?
              end
            end
          end
          workitem.fields['guard_id'] = task_id # ${guard_id} is referenced if guard for execution of this

          failed_tasks = ret_failed_precondition_tasks(task, workflow.guards[:external])
          unless failed_tasks.empty?
            set_task_to_failed_preconditions(task, failed_tasks)
            log_participant.event('precondition_failure', task_id: task_id)
            delete_task_info(workitem)
            return reply_to_engine(workitem)
          end

          action_params = get_action_params(action[:component_actions].first) if action[:component_actions] && action[:component_actions].first
          parameter_defs = action_params[:parameter_defs] if action_params[:parameter_defs]

          task.add_internal_guards!(workflow.guards[:internal])
          execution_context(task, workitem, task_start) do
            require 'byebug'; byebug
            # TODO: DTK-3645
            # If the action is a workflow action we want action.execute_on_server? to be true so it executes the workflow from teh server
            # as opposed to preparing on the server a message to send to the arbiter and then waiting for a callback
            # Using bybug by descending into action.execute_on_server? you wil see that its result is conditional 
            # on config_agent type associated wih action
            # The main logic wil need to go on the method process_executable_action (as opposed to initial instructions to put logic on
            # ret_msg_content
            if action.execute_on_server?
              # The method workflow.process_executable_action for config agent adapters that trigger action.execute_on_server?
              # will end up calling the main function on the config agent adapter 'execute'. An example is a config agent taht we have 
              # not used in a while that has an action def that is a ruby lambda that hets executed on the server. It's methods are in
              # https://github.com/dtk/dtk-server/blob/084447693c851f9ac929fd3402ad30417affab74/lib/config_agent/adapter/ruby_function.rb
              # This was written before we had ruby actions that execute on arbiters so its name is a minsomer. If you look at the
              # execute method you will see logic it does to execute the lambda after binding attributes
              # On the workflow config agent adapter you want to write something that follows the workflow,
              # We wil have to iterate on about launching this in its own thread so it does not become blocking
              result = workflow.process_executable_action(task)
              process_action_result!(workitem, action, result, task, task_id, task_end, false)
              delete_task_info(workitem)
              return reply_to_engine(workitem)
            end

            user_object  = CurrentSession.new.user_object()
            callbacks = {
              on_msg_received: proc do |msg|
                debug = false # TODO: Move this
                inspect_agent_response(msg)
                CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  PerformanceService.end_measurement("#{self.class.to_s.split('::').last}", self.object_id)
                  result = msg[:body].merge('task_id' => task_id)

                  if config_agent_type = action[:config_agent_type]
                    output_matched_dynamic_attr = match_dynamic_attributes(Marshal.load(Marshal.dump(result)), config_agent_type.to_sym, parameter_defs)
                    task.add_action_results(output_matched_dynamic_attr, action) unless output_matched_dynamic_attr.nil?
                  end

                  msg_data = (result[:data] || {})[:data]
                  if msg_data.kind_of?(::Hash)
                    dynamic_attributes = msg_data['dynamic_attributes'] || {}
                    if dtk_debug_port = dynamic_attributes['dtk_debug_port']
                      if public_dns_name = public_dns_name?(action)
                        $public_dns = public_dns_name
                        # Sleep so debug daemon can be ready
                        if wait = R8::Config[:breakpoint][:wait_time_for_daemon]
                          sleep R8::Config[:breakpoint][:wait_time_for_daemon]
                        end
                      end

                      debug = true  
                      if method_name = action.action_method?
                        #debug = false if method_name[:method_name].eql?('delete')
                      end

                      if $port_number.nil? || !$port_number.eql?(dtk_debug_port)
                        $port_number = dtk_debug_port
                      end

                      byebug_host_port_ref = ($public_dns.nil? ? $port_number : "#{$public_dns}:#{$port_number}")
                      port_msg_hash = { info: "Please use 'byebug -R #{byebug_host_port_ref}' to debug current action." }
                      task.add_event(:info, port_msg_hash)
                    else
                      $public_dns = nil
                      $port_number = nil
                    end
                  end

                  if msg_data.kind_of?(::Array) && msg_data.first.has_key?(:error)
                    Log.info("reset port and public_dns")
                    $public_dns = nil
                    $port_number = nil
                  end

                  process_action_result!(workitem, action, result, task, task_id, task_end, debug)
                  delete_task_info(workitem) unless debug
                  status_array = top_task.subtasks.map {|st| st.get_field?(:status)}
                  $public_dns = nil if status_array.all?
                  reply_to_engine(workitem) unless debug
                end
              end,
              on_timeout: proc do
                CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  result = {
                    status: 'timeout'
                  }
                  event, errors = task.add_event_and_errors(:complete_timeout, :server, ['timeout'])
                  if event
                    log_participant.end(:timeout, task_id: task_id, event: event, errors: errors)
                  end
                  cancel_upstream_subtasks(workitem)
                  set_result_timeout(workitem, result, task)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              on_cancel: proc do
                CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  log_participant.canceled(task_id)
                  set_result_canceled(workitem, task)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end
            }

            receiver_context = { callbacks: callbacks, expected_count: 1 }
            workflow.initiate_executable_action(task, receiver_context)
          end
        end

        # Ruote dispatch call to this method in case of user's cancel task request
        def cancel(_fei, flavour)
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          begin
            wi = workitem
            params = get_params(wi)
            task_id, action, workflow, task, task_start, task_end = %w(task_id action workflow task task_start task_end).map { |k| params[k] }
            task.add_internal_guards!(workflow.guards[:internal])
            Log.info_pp(["Canceling task #{action.class}: #{task_id}"])
            callbacks = {
              on_msg_received: proc do |msg|
                inspect_agent_response(msg)
                # set_result_canceled(wi, task)
                # delete_task_info(wi)
                # reply_to_engine(wi)
              end
            }
            receiver_context = { callbacks: callbacks, expected_count: 1 }
            workflow.initiate_cancel_action(task, receiver_context)
          rescue Exception => e
            Log.error("Error in cancel ExecuteOnNode #{e}")
          end
        end

        private

        def add_start_task_event?(task)
          task.add_event(:start)
        end

        def ret_failed_precondition_tasks(task, external_guards)
          ret = []
          guard_task_idhs = task.guarded_by(external_guards)
          return ret if guard_task_idhs.empty?
          sp_hash = {
            cols: [:id, :status, :display_name],
            filter: [:and, [:eq, :status, 'failed'], [:oneof, :id, guard_task_idhs.map(&:get_id)]]
          }
          Model.get_objs(task.model_handle, sp_hash)
        end

        def public_dns_name?(action)
          if node = action[:node]
            unless node.is_assembly_wide_node?
              # TODO: rescue block until full testing of paths
              begin
                host_addresses = NodeComponent.host_addresses_ipv4(node)
                if host_addresses.size == 1
                  host_addresses.first
                end
              rescue => e
                Log.error("Trapped error during host_addresses_ipv4: #{e.inspect}")
                nil
              end
            end
          end
        end

        def process_action_result!(workitem, action, result, task, task_id, task_end, debug = {})
          if errors_in_result = errors_in_result?(result, action)
            event, errors = task.add_event_and_errors(:complete_failed, :config_agent, errors_in_result)
            if event
              log_participant.end(:complete_failed, task_id: task_id, event: event, errors: errors)
            end
            cancel_upstream_subtasks(workitem)
            set_result_failed(workitem, result, task)
          else 
            event = task.add_event(:complete_succeeded, result)
            log_participant.end(:complete_succeeded, task_id: task_id)
            if debug
              set_result_debugging(workitem, result, task, action) 
              task_end = false
            end
            set_result_succeeded(workitem, result, task, action) if task_end
            action.get_and_propagate_dynamic_attributes(result)
          end
        end

        def get_result_data(result)
          (result[:data] || {})[:data] || result[:data] || {}
        end

        def match_dynamic_attributes(result, config_agent_type, parameter_defs)
          return result if config_agent_type.eql? :bash_commands

          dynamic_attr_key = config_agent_type.eql?(:dynamic) ? 'dynamic_attributes' : :dynamic_attributes
          result_data = get_result_data(result)
          return nil if result_data.kind_of?(Array)
          dynamic_attributes = result_data[dynamic_attr_key]
          return result unless dynamic_attributes

          get_result_data(result)[dynamic_attr_key] =
            if !parameter_defs || !(parameters = (parameter_defs[:parameters] || parameter_defs[:parameter]))
              config_agent_type.eql?(:dynamic) ? {} : []
            else
              match_attributes(config_agent_type, dynamic_attributes, parameters)
            end
          result
        end

        def match_attributes(config_agent_type, dynamic_attributes, parameters)
          dynamic_attrs_output = {}
          parameters.each do |k, v|
            if v.key?(:dynamic) && v[:dynamic] == true
              type = v[:type] if v[:type]
              display_format = v[:display_format] if v[:display_format]

              dynamic_attrs_output[k.to_s] =
              if config_agent_type.eql? :dynamic
                { value: dynamic_attributes[k.to_s], type: type, display_format: display_format } if dynamic_attributes[k.to_s]
              elsif config_agent_type.eql? :puppet
                dyn_attr = dynamic_attributes.find{|a| a[:attribute_name] == k.to_s}
                { value: dyn_attr[:attribute_val], type: type, display_format: display_format } if dyn_attr && dyn_attr[:attribute_val]
              end

            end
          end
          dynamic_attrs_output.compact
        end

        def get_action_params(component_action)
          component = component_action.component
          component_template = component.id_handle(id: component[:ancestor_id]).create_object
          method_name = component_action.method_name? || 'create'

          ActionDef.get_matching_action_def_params?(component_template, method_name)
        end
        # TODO: need to turn threading off for now because if dont can have two threads
        # eat ech others messages; may solve with existing mechism or go straight to
        # using stomp event machine
        # may even not be necessary to thread the consume since very fast
        # update: with change so taht subscriptions based on thread global; this may be no longer applicable
        def do_not_thread
          true
        end
      end
    end
  end
end
