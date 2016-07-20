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
  module V1
    class AuthorizationController < V1::Base

      def login
        cred = { username: request.params['username'], password: DataEncryption.hash_it(request.params['password']), c: ret_session_context_id(), access_time: Time.now() }
        handle_and_return_authentication(cred)
      end

      def logout
        user_logout
        { content: nil }
      end

    end
  end
end
