module XYZ
  class Monitoring_itemController < AuthController

    # limit (hours) how long can nodes run
    UP_TIME_LIMIT = R8::Config[:idle][:up_time_hours]

    def list_for_component_display()
      component_or_node_display()
    end
    def node_display()
      component_or_node_display()
    end

    ##
    # Method will get all 'succeeded' assemblies and check their nodes for
    # 'up time'. If one of the nodes has been running more than 'UP_TIME_LIMIT'
    # all nodes of that assembly will be stopped.
    #
    def rest__check_idle()
      prefix_log = "[CRON JOB]"
      Log.info "#{prefix_log} Monitoring idle assemblies: START"

      #find running assemblies
      assemblies = Assembly::Instance.get_assemblies_with_nodes(model_handle()).reject{|a|a[:is_staged]} 

      str_identifer = (assemblies.map { |a| a[:display_name]}).join(', ')

      Log.info "#{prefix_log} Monitoring assemblies: #{str_identifer}"
      aws_connection = CloudConnect::EC2.new

      # check statuses
      assemblies.each do |assembly|
        nodes = assembly[:nodes]
        # flag to indicate if assembly nodes need to be stopped
        stop_this_assembly = false

        nodes.each do |node|
          # status of the nodes
          response = aws_connection.get_instance_status(node.instance_id())

          if response[:status].eql? :running
            if (response[:up_time_hours] >= UP_TIME_LIMIT.to_i)
              stop_this_assembly = true
              break
            end
          end
        end

        # if one of the nodees is running to long we stop all nodes
        if stop_this_assembly
          str_identifer = (nodes.map { |n| n.name }).join(', ')
          Log.info "#{prefix_log} Stopping assembly '#{assembly[:display_name]}', with nodes: '#{str_identifer}'"
          CommandAndControl.stop_instances(nodes)
        end
      end

      Log.info "#{prefix_log} Monitoring idle assemblies: END"


      rest_ok_response({ :status => :ok })
    end

   private
    #helper fn
    def component_or_node_display()
      search_object = ret_search_object_in_request()
      raise Error.new("no search object in request") unless search_object

      model_list = Model.get_objects_from_search_object(search_object)

      #TODO: should we be using default action name
      action_name = :list
      tpl = R8Tpl::TemplateR8.new("#{model_name()}/#{action_name}",user_context())
      _model_var = {}
      _model_var[:i18n] = get_model_i18n(model_name().to_s,user_context())

      set_template_defaults_for_list!(tpl)
      tpl.assign("_#{model_name().to_s}",_model_var)
      tpl.assign("#{model_name()}_list",model_list)

      return {:content => tpl.render()}
    end
  end
end
