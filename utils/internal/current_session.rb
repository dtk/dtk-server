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
  class CurrentSession
    extend Innate::StateAccessor
    state_accessor :user_object, :auth_filters, :access_time, :repoman_session_id

    def get_user_object
      user_object
    end

    def set_repoman_session_id(session_id)
      self.repoman_session_id = session_id
    end

    def set_access_time(a_time)
      self.access_time = a_time
    end

    def last_access_time
      self.access_time
    end

    def get_username
      get_user_object()[:username]
    end

    def get_default_namespace
      get_user_object()[:default_namespace]
    end

    ##
    # This method is used to check if catalog credentials have been preseeded. This is used only on first startup of client.
    #

    def are_catalog_credentials_seeded?
      !!(get_user_object().catalog_username && get_user_object().catalog_password)
    end

    def are_catalog_credentilas_set?
      (get_user_object().catalog_username || get_user_object().catalog_password || R8::Config[:remote_repo][:public][:username])
    end

    def self.is_remote_public_user?
      R8::Config[:remote_repo][:public][:username].eql?(catalog_username)
    end

    def self.user_object
      CurrentSession.new.get_user_object
    end

    def self.get_default_namespace
      CurrentSession.new.get_default_namespace()
    end

    def self.get_username
       CurrentSession.new.get_username()
    end

    def self.are_catalog_credentials_seeded?
      CurrentSession.new.are_catalog_credentials_seeded?
    end

    def self.are_catalog_credentilas_set?
      CurrentSession.new.are_catalog_credentilas_set?()
    end

    def self.catalog_credentials
      usr_obj = CurrentSession.new.get_user_object()
      { username: usr_obj.catalog_username || R8::Config[:remote_repo][:public][:username], password: usr_obj.catalog_password || R8::Config[:remote_repo][:public][:password], pre_hashed: false }
    end

    def self.catalog_username
      catalog_credentials()[:username] || R8::Config[:remote_repo][:public][:username]
    end

    def set_user_object(user_object)
      self.access_time = Time.now
      self.user_object = user_object
    end

    def get_auth_filters
      auth_filters
    end

    def set_auth_filters(*array_auth_filters)
      self.auth_filters = array_auth_filters
    end
  end

  class SessionError < Error
  end
  class SessionTimeout < Error
  end
end