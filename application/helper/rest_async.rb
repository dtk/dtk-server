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
module Ramaze::Helper
  module RestAsync
    def rest_deferred_response(&blk)
      response_procs = {
        ok: lambda do |data|
          JSON.pretty_generate(rest_ok_response(data))
        end,
        notok: lambda do |error|
          error_hash = ::DTK::RestError.create(error).hash_form()
          JSON.pretty_generate(rest_notok_response(error_hash))
        end
      }
      async_callback = request.env['async.callback']
      content_type = 'text/html'
      ::DTK::AsyncResponse.create(async_callback, content_type, response_procs, &blk)
    end
  end
end