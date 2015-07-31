module DTK
  module V1
    class ServiceController < AuthController

      helper :assembly_helper
      helper :task_helper

      def rest__info
        service = service_object()
        rest_ok_response service.info
      end

      def rest__nodes
        service = service_object()
        rest_ok_response service.info_about(:nodes)
      end

      def rest__components
        opts[:filter_proc] = Proc.new do |e|
          if element_matches?(e, [:node, :id], node_id) &&
              element_matches?(e, [:attribute, :component_component_id], component_id)
            if additional_filter_proc.nil? || additional_filter_proc.call(e)
              e
            end
          end
        end
        service = service_object()
        rest_ok_response service.info_about(:components)
      end

      def rest__tasks
        service = service_object()
        rest_ok_response service.info_about(:tasks)
      end

      def rest__access_tokens
        service = service_object()
        rest_ok_response
      end

      def rest__converge
        service = service_object()

        if running_task = most_recent_task_is_executing?(service)
          fail ErrorUsage, "Task with id '#{running_task.id}' is already running in assembly. Please wait until task is complete or cancel task."
        end

        task = Task.create_from_assembly_instance(service, {})
        task.save!()

        workflow = Workflow.create(task)
        workflow.defer_execution()

        rest_ok_response task_id: task.id
      end

      def rest__start
        service = service_object()

        # filters only stopped nodes for this assembly
        nodes, is_valid, error_msg = service.nodes_valid_for_stop_or_start(nil, :stopped)

        unless is_valid
          Log.info(error_msg)
          return rest_ok_response(errors: [error_msg])
        end

        opts = {}
        if (nodes.size == 1)
          opts.merge!(node: nodes.first)
        else
          opts.merge!(nodes: nodes)
        end

        task = Task.task_when_nodes_ready_from_assembly(service, :assembly, opts)
        task.save!()

        Node.start_instances(nodes)

        rest_ok_response task_id: task.id
      end

      def rest__stop
        service = service_object()

        # cancel task if running on the assembly
        if running_task = most_recent_task_is_executing?(service)
          cancel_task(running_task.id)
        end

        nodes, is_valid, error_msg = service.nodes_valid_for_stop_or_start(nil, :running)

        unless is_valid
          Log.info(error_msg)
          return rest_ok_response(errors: [error_msg])
        end

        Node.stop_instances(nodes)

        rest_ok_response
      end

      def rest__create_assembly
        service = service_object()
        rest_ok_response
      end

      def rest__delete_destroy
        service = service_object()

        Assembly::Instance.delete(service.id_handle(), destroy_nodes: true)

        rest_ok_response
      end

    end
  end
end