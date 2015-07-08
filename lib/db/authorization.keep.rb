module XYZ
  module DBAuthorizationClassMixin
    def add_assignments_for_user_info(scalar_assignments,factory_id_handle)
      process_user_info_aux!(:assignments,scalar_assignments,factory_id_handle)
    end

    def update_create_info_for_user_info!(columns,sequel_select,model_handle)
      add_to = process_user_info_aux!(:sequel_select,{},model_handle,columns)
      add_to.empty? ? sequel_select : sequel_select.select_more(add_to).from_self
    end

    def process_user_info_aux!(type,scalar_assignments,model_or_id_handle,columns=nil)
      to_add = {}
      # cleanup if everything should come from model or id handle
      user_obj = CurrentSession.new.get_user_object()
      if user_obj
        update_if_needed!(type,to_add,columns,CONTEXT_ID,user_obj[:c])
        update_if_needed!(type,to_add,columns,:owner_id,user_obj[:id])
      else
        update_if_needed!(type,to_add,columns,CONTEXT_ID,model_or_id_handle[:c])
      end
      raise Error.new("model_or_id_handle[:group_id] not set for #{model_or_id_handle[:model_name]}") unless model_or_id_handle[:group_id] || [:user,:user_group,:user_group_relation].include?( model_or_id_handle[:model_name])#TODO: temp until make sure that this is alwats set
      update_if_needed!(type,to_add,columns,:group_id,model_or_id_handle[:group_id])

      scalar_assignments.merge(to_add)
    end

    def update_if_needed!(type,to_add,columns,col,val)
      if val and not (columns && columns.include?(col))
        to_add.merge!(type == :sequel_select ? {val => col} : {col => val})
        columns << col if columns
      end
    end

    def auth_context
      @auth_context ||= {
        c: [:c,CONTEXT_ID],
        user_id: [:id,:owner_id]
        # special process of :group_id
      }
    end

    def augment_for_authorization(where_clause,model_handle)
      conjoin_set = where_clause ? [where_clause] : []
      auth_filters = NoAuth.include?(model_handle[:model_name]) ? nil : CurrentSession.new.get_auth_filters()
      if auth_filters
# create_dataset_found = caller.select{|x|x =~ /create_dataset'/}
# caller_info = (create_dataset_found ? "CREATE_DATASET_FOUND" : caller[0..15])
# pp [:auth,model_handle[:model_name],auth_filters,caller_info]
#=begin
controller_line = caller.find{|x|x =~ /application\/controller/}
controller = controller_line
if controller_line =~ /controller\/(.+)\.rb:.+`(.+)'/
  model = $1
  fn = $2
  controller = "#{model}##{fn}"
end
unless ["target#get_nodes_status"].include?(controller) #ignore list
  pp [:auth,model_handle[:model_name],controller]
end
        #=end
        conjoin_set += process_session_auth(auth_filters)
      else
        conjoin_set << {CONTEXT_ID => model_handle[:c]} if model_handle[:c]
      end
      case conjoin_set.size
        when 0 then {}
        when 1 then conjoin_set.first
        else SQL.and(*conjoin_set)
      end
    end
    NoAuth = [:user,:user_group,:user_group_relation,:task_event]

    def process_session_auth(auth_filters)
      ret =  []
      user_obj = CurrentSession.new.get_user_object()
      return ret unless user_obj
      auth_filters.each do |auth_filter|
        if auth = auth_context[auth_filter]
          ret << {auth[1] => user_obj[auth[0]]} if user_obj[auth[0]]
        elsif auth_filter == :group_ids
          if group_ids = user_obj[:group_ids]
            ret << {group_id: group_ids}
          end
        end
      end
      ret
    end
  end
end
