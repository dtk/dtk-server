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
  module ComponentUserClassMixin
    def create_user_library_template(model_handle, params)
      pp [:create_user_library_template, model_handle, params]
      username = params['username']
      fail Error.new('missing user name') unless username
      # TODO: stub to get config_agent_type
      config_agent_type = params['config_agent_type'] || 'puppet'
      user_cmp_proc = UserComponentProcessor.create(config_agent_type)
      # TODO: stub to get library
      library_obj = get_objs(model_handle.createMH(:library), cols: [:id]).first
      fail Error.new('cannot find library') unless library_obj
      generic_user_tmpl = user_cmp_proc.find_generic_library_template(library_obj)
      fail Error.new('cannot find user template') unless generic_user_tmpl
      override_attrs = { specific_type: 'user', display_name: "user_#{username}" }
      opts = { ret_new_obj_with_cols: [:id] }
      new_user_obj = library_obj.clone_into(generic_user_tmpl, override_attrs, opts)
      user_cmp_proc.set_virtual_attributes(new_user_obj, username, params)
    end

    private

    class UserComponentProcessor
      def self.create(config_agent_type)
        if config_agent_type == 'puppet'
          UserComponentProcPuppet.new(config_agent_type)
        elsif config_agent_type == 'chef'
          UserComponentProcChef.new(config_agent_type)
        else
          fail Error.new("unknown config_agent_type #{config_agent_typ}")
        end
      end
      def initialize(config_agent_type)
        @config_agent_type = config_agent_type
      end

      def find_generic_library_template(library_obj)
        sp_hash = {
          cols: [:id, :config_agent_type],
          filter: [:eq, :specific_type, 'generic_user']
        }
        library_obj.get_children_objs(:component, sp_hash).find do |cmp|
          cmp[:config_agent_type] == @config_agent_type
        end
      end

      def set_virtual_attributes(user_obj, username, params)
        # TODO: can be more efficient if use update from select
        attr_ids = user_obj.get_children_objs(:attribute, cols: [:id, :display_name]).inject({}) do |h, r|
          h.merge(r[:display_name] => r[:id])
        end
        updates = updates_from_params(username, params)
        update_rows = []
        updates.each do |k, v|
          id = attr_ids[k]
          unless id
            Log.error("virtual attribute #{k} is illegal")
          else
            update_rows << { id: id, value_asserted: v }
          end
        end
        return if update_rows.empty?
        Model.update_from_rows(user_obj.model_handle(:attribute), update_rows)
      end
    end
    class UserComponentProcPuppet < UserComponentProcessor
      def updates_from_params(username, params)
        # required attributes
        ret = {
          'username' => username,
          'fullname' => params['fullname'] || username.capitalize
        }
        if params['has_home_directory'] == 'true'
          ret.merge!('home_dir' => "/home/#{params['home_directory_name'] || username}")
        end
        if params.key?('root_access')
          ret.merge!('root_access' => params['root_access'])
        end
        rsa_pub_keys = []
        (params['ssh_key'] || []).each_with_index do |k, i|
          unless k.empty?
            title = (params['ssh_key_title'] || [])[i]
            fail Error.new("Need title for key in position #{i}") unless title
            rsa_pub_keys << { 'username' => username, 'title' => title, 'key' => k }
          end
        end
        unless rsa_pub_keys.empty?
          ret.merge!('rsa_pub_keys' => rsa_pub_keys)
        end
        ret
      end
    end
    class UserComponentProcChef < UserComponentProcessor
      def updates_from_params(_username, _params)
        fail Error.new('Not implemented yet')
      end
    end
  end
end