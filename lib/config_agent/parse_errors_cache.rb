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
  class ConfigAgent
    class ParseErrorsCache < ErrorUsage
      def initialize(config_agent_type)
        @config_agent_type = config_agent_type
        # indexed by file_path
        @ndx_error_list = {}
      end

      def add(obj, opts = Opts.new)
        if obj.is_a?(ParseError)
          add_error(obj, opts)
        elsif obj.is_a?(self.class)
          unless opts.empty?
            Log.error("Opts should be empty; it is set to: #{opts.inject}}")
          end
          add_errors(obj)
        else
          fail Error.new("Unexpected object type (#{obj.class})")
        end
        self
      end

      def create_error
        msg = "\n"
        num_errs = 0
        @ndx_error_list.each_pair do |file_path, errors|
          ident = IdentInitial
          if file_path
            add_line!(msg, "In file #{file_path}:", ident)
            ident += IdentIncrease
          end
          errors.each do |error|
            num_errs += 1
            add_line!(msg, sentence_capitalize(error.to_s), ident)
          end
        end
        opts = Opts.new(error_prefix: error_prefix(num_errs), log_error: false)
        ErrorUsage::Parsing.new(msg, opts)
      end
      IdentInitial = 2
      IdentIncrease = 2

      attr_reader :ndx_error_list

      private

      def add_error(error, opts = Opts.new)
        # opts[:file_path] could be nil
        ndx = opts[:file_path]
        (@ndx_error_list[ndx] ||= []) << error
        self
      end

      def add_errors(errors)
        errors.ndx_error_list.each_pair do |file_path, errors|
          ndx = file_path
          opts = (file_path ? Opts.new(file_path: file_path) : Opts.new)
          errors.each { |error| add_error(error, opts) }
        end
      end

      def error_prefix(num_errs)
        error_or_errors = (num_errs > 1 ? 'errors' : 'error')
        if @config_agent_type == :puppet
          "Puppet manifest parse #{error_or_errors}"
        else
          "Parse #{error_or_errors}"
        end
      end
    end
  end
end