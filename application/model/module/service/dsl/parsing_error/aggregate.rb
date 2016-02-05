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
module DTK; class ServiceModule
  class ParsingError
    class Aggregate
      def initialize(opts = {})
        @aggregate_error = nil
        @error_cleanup = opts[:error_cleanup]
      end

      def aggregate_errors!(ret_when_err = nil, &_block)
        yield
       rescue DanglingComponentRefs => e
        @aggregate_error = e.add_with(@aggregate_error)
        ret_when_err
       rescue AmbiguousModuleRef => e
        @aggregate_error = e.add_with(@aggregate_error)
        ret_when_err
       rescue Exception => e
        @error_cleanup.call() if @error_cleanup
        raise e
      end

      def raise_error?(opts = {})
        if @aggregate_error
          @error_cleanup.call() if @error_cleanup
          error = @aggregate_error.add_error_opts(Opts.new(log_error: false))
          opts[:do_not_raise] ? error : fail(error)
        end
      end
    end
  end
end; end