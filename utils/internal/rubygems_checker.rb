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
  class RubyGemsChecker
    def self.gem_exists?(name, version)
      response_raw = Common::Response::RestClientWrapper.get_raw "http://rubygems.org/api/v1/versions/#{name}.json"
      response = JSON.parse(response_raw)
      matched = response.select { |v| v['number'] == version }
      return matched != []
    rescue Exception => e
      Log.error "We were not able to check if the specified gem exists, reason: #{e.message}"
      return false
    end
  end
end