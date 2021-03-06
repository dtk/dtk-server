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
  class RestError
    def self.create(err)
      if RestUsageError.match?(err)
        RestUsageError.new(err)
      elsif NotFound.match?(err)
        NotFound.new(err)
      else
        Internal.new(err)
      end
    end
    def initialize(_err)
      @code = nil
      @message = nil
      @backtrace = nil
    end

    def hash_form
      ret = { code: code || :error, message: message || '' }
      ret.merge!(backtrace: backtrace) if @backtrace
      ret
    end

    private

     attr_reader :code, :message, :backtrace

    public

    # its either its a usage or and internal (application error) bug
    class Internal < RestError
      def hash_form
        ret = super.merge(internal: true)
        ret.merge!(backtrace: @backtrace) if @backtrace
        ret
      end

      private

      def initialize(err)
        super
        # @message = "#{err.to_s} (#{err.backtrace.first})"
        # Do not see value of exposing single line to client, we will still need logs to trace the error
        @message = err.to_s
        if R8::Config[:debug][:show_backtrace] == true
          @backtrace = err.backtrace
        end
      end
    end
    class RestUsageError < RestError
      def initialize(err)
        super
        @message = err.to_s
      end
      def self.match?(err)
        err.is_a?(ErrorUsage)
      end
    end
    class NotFound < RestUsageError
      def self.match?(err)
        err.is_a?(::NoMethodError) && is_controller_method(err)
      end
      def initialize(err)
        super
        @code = :not_found
        @message = "'#{err.name}' was not found"
        if R8::Config[:debug][:show_backtrace] == true
          @backtrace = err.backtrace
        end
      end

      private

      def self.is_controller_method(err)
        err.to_s =~ /#<XYZ::.+Controller:/
      end
    end
  end
end