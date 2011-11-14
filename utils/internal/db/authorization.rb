module XYZ
  module DBAuthorizationClassMixin
    def augment_for_authorization(where_clause,model_handle)
      conjoin_set = where_clause ? [where_clause] : Array.new 
      session = CurrentSession.new
      auth_filters = NoAuth.include?(model_handle[:model_name]) ? nil : session.get_auth_filters()
      if auth_filters 
=begin
create_dataset_found = caller.select{|x|x =~ /create_dataset'/}
caller_info = (create_dataset_found ? "CREATE_DATASET_FOUND" : caller[0..15])
pp [:auth,model_handle[:model_name],auth_filters,caller_info]
=end
#=begin
controller_line = caller.find{|x|x =~ /application\/controller/}
controller = controller_line
if controller_line =~ /controller\/(.+)\.rb:.+`(.+)'/
  model = $1
  fn = $2
  controller = "#{model}##{fn}"
end
pp [:auth,model_handle[:model_name],controller]
#=end
        conjoin_set += process_session_auth(session,auth_filters)
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

    def process_session_auth(session,auth_filters)
      ret =  Array.new
      user_obj = session.get_user_object()
      return ret unless user_obj
      auth_filters.each do |auth_filter|
        if auth = auth_context[auth_filter]
          ret << {auth[1] => user_obj[auth[0]]} if user_obj[auth[0]]
        elsif auth_filter == :group_ids
          if group_ids = user_obj[:group_ids]
            if group_ids.size == 1 
              ret << {:group_id => group_ids.first}
            elsif group_ids.size > 1 
              Log.error("currently not treating case where multiple members of group_ids")
            end
          end
        end
      end
      ret
    end
  end
end
