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
module XYZ
  module DBAuthorizationClassMixin
    def add_assignments_for_user_info(scalar_assigns, factory_id_handle)
      scalar_assigns.merge(process_user_info_aux(scalar_assigns, factory_id_handle))
    end

    def user_info_for_create_seleect(overrides, model_handle)
      process_user_info_aux(overrides, model_handle)
    end

    def process_user_info_aux(scalar_assigns, model_or_id_handle)
      # cleanup if everything should come from model or id handle
      user_obj = CurrentSession.new.get_user_object()
      assigns = {}
      if user_obj
        assigns.merge!(CONTEXT_ID => user_obj[:c], :owner_id => user_obj[:id])
      else
        assigns.merge!(CONTEXT_ID => model_or_id_handle[:c])
      end

      unless model_or_id_handle[:group_id] || [:user, :user_group, :user_group_relation, :repo_remote].include?(model_or_id_handle[:model_name]) #TODO: temp until make sure that this is alwats set
        bad_item =
          if model_or_id_handle.is_a?(IDHandle)
            "id handle with type (#{model_or_id_handle[:model_name]}) and id (#{model_or_id_handle.get_id()})"
          else #is model handle
            "model handle with type(#{model_or_id_handle[:model_name]})"
          end
        fail Error.new("model_or_id_handle[:group_id] not set for #{bad_item}")
      end
      assigns.merge!(group_id: model_or_id_handle[:group_id])
      # remove if in overrides or null val
      assigns.inject({}) { |h, (col, val)| (val and not scalar_assigns.key?(col)) ? h.merge(col => val) : h }
    end

    def auth_context
      @auth_context ||= {
        c: [:c, CONTEXT_ID],
        user_id: [:id, :owner_id]
        # special process of :group_id
      }
    end

    def augment_for_authorization(where_clause, model_handle)
      conjoin_set = where_clause ? [where_clause] : []
      auth_filters = NoAuth.include?(model_handle[:model_name]) ? nil : CurrentSession.new.get_auth_filters()
      if auth_filters
        # controller_line = caller.find{|x|x =~ /application\/controller/}
        # controller = controller_line
        # if controller_line =~ /controller\/(.+)\.rb:.+`(.+)'/
        #   model = $1
        #   fn = $2
        #   controller_action = "#{model}##{fn}"
        # end
        # mn = model_handle[:model_name]
        # unless [:task_log].include?(mn) or ["target#get_nodes_status", "task#get_logs"].include?(controller_action) #ignore list
        #   username = CurrentSession.new.get_username()
        #   pp [:auth,username,mn,controller_action]
        # end
        conjoin_set += process_session_auth(CurrentSession.new, auth_filters)
      else
        conjoin_set << { CONTEXT_ID => model_handle[:c] } if model_handle[:c]
      end
      case conjoin_set.size
        when 0 then {}
        when 1 then conjoin_set.first
        else SQL.and(*conjoin_set)
      end
    end
    NoAuth = [:user, :user_group, :user_group_relation, :task_event]

    def process_session_auth(session, auth_filters)
      ret =  []
      user_obj = session.get_user_object()
      return ret unless user_obj
      auth_filters.each do |auth_filter|
        if auth = auth_context[auth_filter]
          ret << { auth[1] => user_obj[auth[0]] } if user_obj[auth[0]]
        elsif auth_filter == :group_ids
          if group_ids = user_obj[:group_ids]
            ret << { group_id: group_ids }
          end
        end
      end
      ret
    end
  end
end