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
  class MetadataController < Controller
    def rest__get_metadata
      metadata_file = ret_non_null_request_params(:metadata_file)
      file = File.open(File.expand_path("../meta/tables_metadata/#{metadata_file}.json", File.dirname(__FILE__))).read
      rest_ok_response file
    end
  end
end
