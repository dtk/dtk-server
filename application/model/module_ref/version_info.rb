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
module DTK; class ModuleRef
  class VersionInfo
    DEFAULT_VERSION = nil

    class Assignment < self
      def initialize(version_string)
        @version_string = version_string
      end

      attr_reader :version_string

      def self.reify?(object)
        version_string =
          if object.is_a?(String)
            ModuleVersion.string_master_or_empty?(object) ? DEFAULT_VERSION : object
          elsif object.is_a?(ModuleRef)
            version_info = object[:version_info] 
            ModuleVersion.string_master_or_empty?(version_info) ? DEFAULT_VERSION : version_info
          end

         if version_string
           if ModuleVersion::Semantic.legal_format?(version_string)
             new(version_string)
           else
            fail Error.new("Unexpected form of version string (#{version_string})")
          end
        end
      end

      def to_s
        @version_string
      end
    end

    class Constraint < self
      def ret_version
        if is_scalar?() then is_scalar?()
        elsif empty? then nil
        else
          fail Error.new("Not treating the version type (#{ret.inspect})")
        end
      end

      def self.reify?(constraint = nil)
        if constraint.nil? then new()
        elsif constraint.is_a?(Constraint) then constraint
        elsif constraint.is_a?(String) then new(constraint)
        elsif constraint.is_a?(Hash) && constraint.size == 1 && constraint.keys.first == 'namespace'
          # MOD_RESTRUCT: TODO: need to decide if depracting 'namespace' key
          Log.info("Ignoring constraint of form (#{constraint.inspect})")
          new()
        else
          fail Error.new("Constraint of form (#{constraint.inspect}) not treated")
        end
      end

      def include?(version)
        case @type
        when :empty
          nil
        when :scalar
          @value == version
        end
      end

      def is_scalar?
        @value if @type == :scalar
      end

      def empty?
        @type == :empty
      end

      def to_s
        case @type
        when :scalar
          @value.to_s
        end
      end

      private

      def initialize(scalar = nil)
        @type = (scalar ? :scalar : :empty)
        @value = scalar
      end
    end
  end
end; end