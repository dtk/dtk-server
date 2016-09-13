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
    class DiffErrors < ErrorUsage
      def initialize(error_msgs)
        super(error_msg(error_msgs))
      end
      private :initialize
      
      def self.raise_if_any_errors(diff_result)
        error_msgs = diff_result.error_msgs
        fail new(error_msgs) unless error_msgs.empty?
      end

      private

      IDENT = 2
      def error_msg(error_msgs)
        error_msgs = [error_msgs] unless error_msgs.kind_of?(::Array)
        if error_msgs.size == 1
          error_msgs.first
        else
          error_msgs.inject("\n") { |str, error_msg| "#{str}#{' ' * IDENT}#{error_msg}\n" }
        end
      end
    end
  end
end
