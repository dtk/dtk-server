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
# TODO: clean up

module DTK
  # Base controller
  class Controller < ::Ramaze::Controller
    ENCRYPTION_SALT = R8::Config[:encryption][:cookie_salt]

    helper :common
    helper :version_helper
    helper :general_processing
    helper :process_search_object
    helper :user
    helper :rest
    helper :bundle_and_return_helper
    helper :authentication

    trait user_model: XYZ::User

    include R8Tpl::CommonMixin
    include R8Tpl::Utility::I18n

    provide(:html, type: 'text/html') { |_a, s| s } #lamba{|a,s|s} is fn called after bundle and render for a html request
    provide(:json, type: 'application/json') { |_a, s| s }

    layout :bundle_and_return

    helper :aspect

    def bundle_and_return
      rest_response()
    end

    # error handling
    def handle_errors(&_block)
      yield
    rescue ErrorUsage => e
      { data: {
          'error' => {
            'error_code' => 1,
            'error_msg' => e.to_s
          }
        }
      }
    end

    private

    def user_context
      @user_context ||= UserContext.new(self)
    end

    def http_host
      request.env['HTTP_HOST']
    end
  end

  # END of Controller
  class AuthController < Controller
    before_all do
      # Suspending this check for this time
      check_user_authentication
    end

    def check_user_authentication
      current_session = CurrentSession.new

      if R8::Config[:session][:timeout][:disabled]
        Log.debug 'User session timeout has been disabled!'
        return
      end

      if current_session.get_user_object().nil?
        # check requests for AUTHENTICATION HEADERS
        simple_auth_login = false
        simple_http_auth_creds = check_simple_http_authentication()
        simple_auth_login = login_without_response(login_without_response) if login_without_response

        # authentication passed
        if simple_auth_login
          Log.debug('Session created using simple HTTP authentication credentials')
          return
        end

        # Log.info "Missing authentication credentials, please log in again and re-try your request"
        fail DTK::SessionError, 'Missing authentication credentials, please log in again and re-try your request'
      end

      session.store(:last_ts, Time.now.to_i) if session.fetch(:last_ts).to_i == 0

      if (Time.now.to_i - session.fetch(:last_ts).to_i) > (R8::Config[:session][:timeout][:hours].to_i).hours
        # session expired
        # Log.info "Session has expired due to inactivity, please log in again"
        fail DTK::SessionTimeout, 'Session has expired due to inactivity, please log in again'
      else
        session.store(:last_ts, Time.now.to_i)
        # current_session.set_access_time(Time.now)
      end
    end
  end
end


# system fns for controller
require __DIR__('action_set')

%w(account library target state_change node_group node component attribute user task assembly messages component_module service_module test_module node_module metadata namespace integration developer).each do |controller_file|
  require __DIR__(controller_file)
end

# this must be after AuthController
require_relative('v1')
