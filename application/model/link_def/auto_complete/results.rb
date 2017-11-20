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
  class LinkDef::AutoComplete
    class Results < ::Array 
      def fail_if_any_errors
        error_result_array = select { | result | result.severity_level == :error }
        fail ErrorUsage, message(:error, error_result_array) unless error_result_array.empty?
      end
      
      def warning_message?
        warning_result_array =  select { | result | result.severity_level == :warning }
        message(:warning, warning_result_array) unless warning_result_array.empty? 
      end
      
      private
      
      INDENT = 2
      
      def message(type, result_array)
        message_start = (result_array.size == 1 ?
                         "The following #{type} was detected during auto linking:\n" :
                         "The following #{type}s were detected during auto linking:\n")
        result_array.inject(message_start) {  |str, result| str + "#{' ' * INDENT}#{result.message}\n" }
      end

    end
  end
end
