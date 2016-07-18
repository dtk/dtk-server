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
  class Model
    class SpHash < ::Hash
      module Mixin
        def sp_filter(*args)
          SpHash.new.cols(*SpHash.base_cols).filter(*args)
        end

        def sp_cols(*cols)
          SpHash.new.cols(*cols)
        end
      end

      def cols(*cols)
        merge(cols: cols)
      end

      def filter(*args)
        filter =
          case args.size
          when 0
            nil
          when 1
            arg = args.first
            raise Error.new("Illegal form for args: #{args.inspect}") unless arg.kind_of?(Array)
            arg
          else
            args
          end
        filter ? merge(filter: filter) : self
      end

      def self.base_cols
        [:id, :group_id, :display_name]
      end
    end
  end
end
