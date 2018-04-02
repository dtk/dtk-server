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
  # TODO: did not put in XYZ module because Ramaze user helper access ::User
  # include XYZ
  class User < Model
    def self.common_columns
      [
        :c,
        :id,
        :username,
        :password,
        :user_groups,
        :default_namespace,
        :catalog_username,
        :catalog_password
      ]
    end

    def self.create_user_in_groups?(user_mh, username, opts = {})
      groupnames = [UserGroup.all_groupname(), UserGroup.private_groupname(username)]
      user_hash = Aux.HashHelper(
        password: DataEncryption.hash_it(opts[:password] || random_generate_password()),
        default_namespace: opts[:namespace] || username,
        catalog_password: SSHCipher.encrypt_password(opts[:catalog_password]),
        catalog_username: opts[:catalog_username]
      )

      user_id = create_from_row?(user_mh, username, { username: username }, user_hash).get_id()
      groupnames.each do |groupname|
        group_id = create_from_row?(user_mh.createMH(:user_group), groupname, groupname: groupname).get_id
        create_from_row?(user_mh.createMH(:user_group_relation), "#{username}-#{groupname}", user_id: user_id, user_group_id: group_id)
      end
      get_user(user_mh, username)
    end

    def self.authenticate(hash)
      username = hash[:username]
      password = hash[:password]
      model_handle = ModelHandle.new(hash[:c], :user)
      if user = get_user(model_handle, username)
        user if user.authenticated?(password)
      end
    end

    def get_namespace
      # TODO: [Haris] Add namespace to database got to double check with Rich
      self[:username]
    end

    def username
      self[:username] || self.update_object!(:username)[:username]
    end

    def catalog_username
      self[:catalog_username] || self.update_obj!(:catalog_username)[:catalog_username]
    end

    def catalog_password
      hashed_password = self[:catalog_password] || self.update_obj!(:catalog_password)[:catalog_password]
      ::DTK::SSHCipher.decrypt_password(hashed_password)
    end

    # TODO: temp
    def authenticated?(hashed_password)
      self[:password] && (self[:password] == hashed_password)
    end

    def self.get_user(model_handle, username)
      sp_hash = {
        relation: :user,
        filter: [:and, [:eq, :username, username]],
        columns: common_columns()
      }

      get_full_user(model_handle, sp_hash)
    end

    def self.get_user_by_id(model_handle, user_id)
      sp_hash = {
        relation: :user,
        filter: [:and, [:eq, :id, user_id.to_i]],
        columns: common_columns()
      }

      get_full_user(model_handle, sp_hash)
    end

    def get_setting(key)
      (self[:settings] || {})[key]
    end

    def public_keys()
      sp_hash = {
        cols: [:id, :display_name, :ssh_rsa_pub_key, :repo_manager_direct_access],
        filter: [:eq, :owner_id, self.id]
      }
      RepoUser.get_objs(model_handle(:repo_user), sp_hash)
    end

    def remote_public_keys()
      sp_hash = {
        cols: [:id, :display_name, :ssh_rsa_pub_key, :repo_manager_direct_access],
        filter: [:and,[:eq, :owner_id, self.id],[:eq, :repo_manager_direct_access, true]]
      }
      RepoUser.get_objs(model_handle(:repo_user), sp_hash)
    end

    def get_private_group
      # makes assumption taht private group is one where username and groupname are the same
      # TODO: more efficient way of getting this
      group_rows = get_objs(cols: [:username, :user_groups])
      # TODO: probably better to put in attribute for group which means user private group rather than having naming convention assumption here
      selected_row = group_rows.find { |r| r[:user_group][:groupname] == "user-#{r[:username]}" }
      selected_row && selected_row[:user_group]
    end

    def update_password(password)
      update_hash = { id: id(), password: DataEncryption.hash_it(password) }
      Model.update_from_rows(model_handle, [update_hash])
    end

    def to_json_hash
      json_string = JSON_FIELDS.inject({}) { |res, field| res.merge!(field => self[field]) }
      json_string
    end

    private

    def self.random_generate_password
      Aux.random_generate(length: 8, type: /[a-z]/)
    end

    def self.get_full_user(model_handle, sp_hash)
      rows = Model.get_objs(model_handle, sp_hash)
      return nil if rows.empty?
      # all rows will be same except for on :user_group and :user_group_relation cols
      group_ids = rows.map { |r| (r[:user_group] || {})[:id] }.compact
      filtered_rows = rows.first.reject! { |k, _v| [:user_group, :user_group_relation].include?(k) }
      filtered_rows.merge(group_ids: group_ids)
    end

    JSON_FIELDS = [:c, :id, :username, :password, :group_ids, :default_namespace]

    def self.from_json(json_string)
      user_object = self.new({}, json_string[:c])
      json_string.each do |k, v|
        user_object[k.to_sym] = v
      end

      user_object
    end

    def self.create_user_session_hash(user_object)
      return {} unless user_object
      {
        'credentials' => {
               'username' => user_object[:username],
               'password' => user_object[:password],
               'c' => user_object[:c],
               'default_namespace' => user_object[:default_namespace],
               'access_time' => Time.now.to_s
        }
      }
    end

  end
end