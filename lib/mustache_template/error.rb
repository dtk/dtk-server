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
  module MustacheTemplate
    class Error < ::DTK::ErrorUsage
      def initialize(err_msg)
        @error_message = err_msg
      end
      attr_reader :error_message
      
      def to_s
        @error_message
      end
      
      private
      
      def add_file_path?(err_msg, opts = {})
        file_path = opts[:file_path]
        file_path ? "#{err_msg} '#{file_path}'" : err_msg
      end
      
      class SyntaxError < self
        def initialize(err_msg, opts = {})
          super("#{add_file_path?('Unable to parse Mustache template', opts)}:\n#{err_msg}")
        end
      end
      
      class MissingVar < self
        attr_reader :missing_var
        def initialize(missing_var, opts = {})
          super(add_file_path?("Mustache variable '#{missing_var}' is not bound in mustache template", opts))
          @missing_var = missing_var
        end
        private :initialize
        
        def self.create(err_msg, opts = {})
          if err_msg =~ /^Can't find ([^\s]+) in/
            missing_var = Regexp.last_match(1)
            new(missing_var, opts)
          else
            Error.new(add_file_path?(err_msg, opts))
          end
        end

      end
    end
  end
end
