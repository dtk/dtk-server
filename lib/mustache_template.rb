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
require 'mustache'

module DTK
  module MustacheTemplate
    require_relative('mustache_template/error')

    def self.needs_template_substitution?(string)
      # will return true if string has mustache template attributes '{{ variable }}'
      if string
        !!(string =~ HAS_MUSTACHE_VARS_REGEXP)
      end
    end
    HAS_MUSTACHE_VARS_REGEXP = /\{\{.+\}\}/

    # block_for_err takes mustache_gem_err,string
    # opts can have keys
    #   :file_path
    #   :remove_empty_lines (Boolean)
    #   :raise_error_on_missing_var (Boolean) - default is true
    def self.render(string, attr_val_pairs, opts={})
      begin
        missing_var_check = (opts[:raise_error_on_missing_var].nil? ? true : opts[:raise_error_on_missing_var])
        ::Mustache.raise_on_context_miss = missing_var_check
        ret = ::Mustache.render(string, attr_val_pairs)
        if opts[:remove_empty_lines]
          # extra empty lines can be due to Mustache for loop behavior
          ret = (ret || '').gsub(/\|(\r?\n)+\|/m, "|\n|")
        end
        ret
       rescue ::Mustache::Parser::SyntaxError => e
        fail Error::SyntaxError.new(e.message, opts)
       rescue ::Mustache::ContextMiss => e
        fail Error::MissingVar.create(e.message, opts)
      end
    end
  end
end
