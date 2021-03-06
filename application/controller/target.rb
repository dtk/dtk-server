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
  class TargetController < AuthController
    helper :target_helper

    PROVIDER_PREFIX    = 'provider'
    PROVIDER_DELIMITER = ':::'

    def rest__list
      subtype   = ret_target_subtype()
      parent_id = ret_request_params(:parent_id)

      response =
        if subtype.eql? :instance
          opts = ((parent_id && !parent_id.empty?) ? { filter: [:eq, :parent_id, parent_id] } : {})
          Target::Instance.list(model_handle(), opts)
        elsif subtype.eql? :template
          Target::Template.list(model_handle())
        else
          fail ErrorUsage.new("Illegal subtype param (#{subtype})")
        end
      rest_ok_response response
    end

    def rest__info
      target = create_obj(:target_id, Target::Instance)
      rest_ok_response target.info(), encode_into: :yaml
    end

    def rest__import_nodes
      target = create_obj(:target_id, Target::Instance)
      #TODO: formatting to get right fields is done on client side now; should be done on server side
      #method Node::TargetRef:InventoryData.new can be removed or modified once that is done
      inventory_data_hash = ret_non_null_request_params(:inventory_data)
      inventory_data = Node::TargetRef::Input::InventoryData.new(inventory_data_hash)
      rest_ok_response Target::Instance.import_nodes(target, inventory_data)
    end

    def rest__install_agents
      target = create_obj(:target_id)
      target.install_agents()
      rest_ok_response
    end

    def rest__task_status
      target = create_obj(:target_id)
      target_idh = target.id_handle()

      format = (ret_request_params(:format) || :hash).to_sym
      response = Task::Status::Target.get_status(target_idh, format: format)
      rest_ok_response response
    end

    # create target instance
    def rest__create
      provider        = create_obj(:provider_id, Target::Template)
      target_type     = ret_request_params(:type) 
      opts            = ret_params_hash(:target_name)
      project_idh     = get_default_project().id_handle()

      iaas_properties = nil
      # if target_type is null that means generic target that can support multiple IAAS types
      if target_type
        target_type = target_type.to_sym
        iaas_properties = ret_non_null_request_params(:iaas_properties).inject({}) { |h, (k, v)| h.merge(k.to_sym => v) }  
        #TODO: for legacy: can be removed when clients upgraded
        iaas_properties[:region] ||= ret_request_params(:region)
      end
      Target::Instance.create_target(target_type, project_idh, provider, iaas_properties, opts)
      rest_ok_response
    end

    def rest__create_provider
      iaas_type       = ret_request_params(:iaas_type) # if nil means that its a generic provider
      provider_name   = ret_non_null_request_params(:provider_name)
      iaas_properties = ret_request_params(:iaas_properties)
      params_hash     = ret_params_hash(:description)
      no_bootstrap    = ret_request_param_boolean(:no_bootstrap) || true

      project_idh  = get_default_project().id_handle()
      # setting :error_if_exists only if no bootstrap
      opts = { raise_error_if_exists: no_bootstrap }
      provider = Target::Template.create_provider?(project_idh, iaas_type, provider_name, iaas_properties, params_hash, opts)
      response = { provider_id: provider.id }

      # TODO: removing until provides for fact that need to know when ec2 whether vpc or classic
      # unless no_bootstrap
      #  # select_region could be nil
      #  created_targets_info = provider.create_bootstrap_targets?(project_idh,selected_region)
      #  response.merge!(:created_targets => created_targets_info)
      # end
      rest_ok_response response
    end

    def rest__delete_and_destroy
      type = (ret_request_params(:type) || :instance).to_sym # can be :instance or :template
      # TODO: stubbed now to have force being true; now only Target::Template.delete_and_destroy supports non force; so not passing in
      # force param to Target::Instance.delete_and_destroy
      force = true
      response = {}
      case type
       when :template
        provider  = create_obj(:target_id, Target::Template)
        response = Target::Template.delete_and_destroy(provider, force: force)
       when :instance
        target_instance = create_obj(:target_id, Target::Instance)
        response = Target::Instance.delete_and_destroy(target_instance)
       else
        fail ErrorUsage.new("Illegal type '#{type}'")
      end
      rest_ok_response response
    end

    def rest__set_properties
      target_instance = create_obj(:target_id, Target::Instance)
      iaas_properties = ret_request_params(:iaas_properties)
      Target::Instance.set_properties(target_instance, iaas_properties)
      rest_ok_response
    end

    def rest__set_default
      target_instance = create_obj(:target_id, Target::Instance)
      update_workspace_target = true #TODO: stubbed might make this option passed by client
      Target::Instance.set_default_target(target_instance, update_workspace_target: update_workspace_target)
      rest_ok_response
    end

    def rest__info_about
      target = create_obj(:target_id)
      about = ret_non_null_request_params(:about).to_sym
      opts = ret_params_hash(:detail_level, :include_workspace)
      rest_ok_response target.info_about(about, opts)
    end
  end
end
