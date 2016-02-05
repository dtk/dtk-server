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
  module CreateThread
    def self.defer_with_session(user_object, current_session, &block)
      Ramaze.defer(&wrap(user_object, current_session, &block))
    end

    private

    def self.defer(&block)
      Ramaze.defer(&wrap(&block))
    end

    # wrap() - Added this part of code so if thread fails we will know imedietly. Helps with development,
    # in case there is some internal logic that expects some thread to fail error messages can be
    # ignored or this call

    def self.wrap(user_object = nil, current_session, &_block)
      lambda do
        begin
          # this part of code sets session information to make sure that newly created thread keeps its session
          # this was necessery due to concurency issues
          if user_object
            Thread.current[:user_object] = user_object

            #
            # There is passenger issue that forced our hand to send current_session from main thread.
            #
            # This has been tested with concurrent user converging assemblies at the same time and it is working.
            #

            if current_session
              current_session[:USER] = ::DTK::User.create_user_session_hash(user_object)
            end
          end

          # yield original block
          yield

          # end
        rescue Exception => e
          Log.fatal("ERROR IN THREAD #{e.message} #{e.backtrace}")
          Log.error_pp(['ERROR IN THREAD', e.message, e.backtrace])
        end
      end
    end
  end
end