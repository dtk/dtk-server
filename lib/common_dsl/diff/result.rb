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
  class CommonDSL::Diff
    class Result
      attr_writer :repo_updated
      attr_reader :items_to_update
      def initialize
        @repo_updated    = false # if true, means repo updated by server
        @items_to_update = [] # items in repo that server needs to update
        @warning_msgs    = []
        @error_msgs      = []
      end

      def add_warning_msg(msg)
        @warning_msgs << msg
      end

      def add_error_msg(msg)
        @error_msgs << msg
      end

      def hash_for_response
        {
          repo_updated: @repo_updated,
          warning_msgs: @warning_msgs,
          error_msgs: @error_msgs
        }
      end

      def any_errors?
        !@error_msgs.empty?
      end
      
      UPDATE_ITEMS = [:workflow, :assembly]
      def add_item_to_update(item)
        fail Error, "Illegal update item '#{item}'"  unless UPDATE_ITEMS.include?(item)
        @items_to_update << item unless @items_to_update.include?(item)
      end

    end
  end
end
