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
    class MetadataController < Base
      helper :common

      TABLE_METADATA_DIR = File.expand_path('../../meta/tables_metadata', File.dirname(__FILE__))

      def get
        metadata_file = ret_non_null_request_params(:metadata_file)
        json_file_content = File.open("#{TABLE_METADATA_DIR}/#{metadata_file}.json").read
        rest_ok_response json_file_content
      end
    end
  end
end
