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
module DTK; class Task::Status
  class HashOutput              
    class Detail
      dtk_nested_require('detail', 'executable_action')
      
      def initialize(hash_output, task)
        @hash_output = hash_output
        @task        = task
      end
      
      def self.add_details?(hash_output, task)
        new(hash_output, task).add_details?
      end
      
      def add_details?
        ExecutableAction.add_components_and_actions?(@hash_output, @task)
        set?(:action_results, action_results?())
        set?(:errors, errors?())
        @hash_output
      end
      
      private
      
      def action_results?
        if action_results = @task[:action_results]
          ret = action_results.map do |a| 
            Aux.hash_subset(a, ActionResultFields) 
          end.compact
          ret.empty? ? nil : ret
        end
      end
      ActionResultFields = [:status, :stdout, :stderr, :description]

      ErrorFields = [:message, :type]
      def errors?
        if errors = @task[:errors]
          ret = errors.map do |e|
            if e.kind_of?(String)
              { message: sanitize_message(e) }
            elsif e.kind_of?(Hash)
              err_hash = Aux.hash_subset(e, ErrorFields)
              if msg = err_hash[:message]
                err_hash[:message] = sanitize_message(msg) 
              end
              err_hash.empty? ? nil : err_hash
            end
          end.compact
          ret.empty? ? nil : ret
        end
      end

      def set?(key, value)
        unless value.nil?
          @hash_output[key] = value
        end
      end

      require 'iconv'
      IC = Iconv.new('UTF-8//IGNORE', 'UTF-8')
      def sanitize_message(msg)
        sanitize_message_aux(IC.iconv(msg))
      end

      RegexpMatch = /\[1\;31m/
      def sanitize_message_aux(msg)
        if pos = msg =~ RegexpMatch
          msg.sub!(RegexpMatch, "\n")
          # remove garbage charcter
          msg[pos - 1] = ''
          sanitize_message_aux(msg)
        else
          msg
        end
      end

      def sanitize_message2(msg)
        ret = IC.iconv(msg)
        ret.gsub(RegexpMatch, "\n")
      end
    end
  end
end; end
