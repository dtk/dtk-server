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
module DTK; module CommonDSL::Generate
  class ContentInput::Diff
    class Base < self
      require_relative('base/collate')

      include Collate::Mixin

      attr_reader :current_val, :new_val, :id_handle, :qualified_key
      # opts can have keys
      #   :qualified_key (required)
      #   :id_handle (required)
      def initialize(current_val, new_val, opts = {})
        super()
        unless @qualified_key = opts[:qualified_key]
          raise Error, "Unexpected that opts[:qualified_key] is nil"
        end
        unless @id_handle = opts[:id_handle]
          raise Error, "Unexpected that opts[:id_handle] is nil"
        end
        @current_val = current_val
        @new_val     = new_val
      end

      def id_handle
        @id_handle || raise(Error, "Unexpected that @id_handle is nil")
      end

      def qualified_key
        @qualified_key || raise(Error, "Unexpected that @qualified_key is nil")
      end
      
      # opts can have keys
      #   :qualified_key
      #   :id_handle
      def self.diff?(current_val, new_val, opts = {})
        new(current_val, new_val, opts) if has_diff?(current_val, new_val)
      end
      
      private

      def create_modify_element
        self.class::Modify.new(self)
      end

      def self.has_diff?(current_val, new_val)
        no_diff = false
        if current_val.respond_to?(:to_s) and new_val.respond_to?(:to_s) and current_val.to_s == new_val.to_s
          no_diff = true
        elsif current_val.class == new_val.class and current_val == new_val
          no_diff = true
        end
        !no_diff
      end
      
    end
  end
end; end
