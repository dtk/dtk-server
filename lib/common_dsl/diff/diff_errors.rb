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
  module CommonDSL
    class Diff
      class DiffErrors < ErrorUsage
        attr_reader :error_msgs, :create_backup_file
        # opts can have keys:
        #   :create_backup_file
        def initialize(error_msgs, opts = {})
          error_msgs = [error_msgs] unless error_msgs.kind_of?(::Array)
          super(error_msg(error_msgs))
          @error_msgs         = error_msgs
          @create_backup_file = opts[:create_backup_file]
        end
        private :initialize
        
        def self.raise_if_any_errors(diff_result)
          error_msgs = diff_result.error_msgs
          fail new(error_msgs) unless error_msgs.empty?
        end
        
        def self.process_diffs_error_handling(diff_result, service_instance_gen, &block)
          begin
            block.call
          rescue DiffErrors => diff_errors
            if diff_errors.create_backup_file
              set_result_when_create_backup_file!(diff_result, diff_errors, service_instance_gen)
            else
              raise diff_errors
            end
          end
          diff_result
        end
        
        private
        
        def self.set_result_when_create_backup_file!(diff_result, diff_errors, service_instance_gen)
          diff_errors.error_msgs.each { |error_msg| diff_result.add_error_msg(error_msg) }
          backup_path = FileType::ServiceInstance.backup_path
          canonical_path = FileType::ServiceInstance.canonical_path
          diff_result.add_info_msg("Previous state of file '#{canonical_path}' stored as '#{backup_path}'") 
          diff_result.add_backup_file(backup_path, service_instance_gen.yaml_dsl_text)
          diff_result.clear_semantic_diffs!
          diff_result
        end
        
        IDENT = 2
        def error_msg(error_msgs)
          if error_msgs.size == 1
            error_msgs.first
          else
            error_msgs.inject("\n") { |str, error_msg| "#{str}#{' ' * IDENT}#{error_msg}\n" }
          end
        end

      end
    end
  end
end
