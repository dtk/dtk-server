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
      require_relative('diff/service_instance')
      require_relative('diff/result')
      require_relative('diff/serialized_hash')
      require_relative('diff/collated.rb')
      require_relative('diff/qualified_key')
      require_relative('diff/repo_update')
      require_relative('diff/diff_errors')
      require_relative('diff/element')

      require_relative('diff/base')
      require_relative('diff/set')

      attr_reader :qualified_key, :service_instance
      # opts can have keys
      #   :qualified_key 
      #   :service_instance
      #   :type
      def initialize(opts = {})
        @qualified_key = opts[:qualified_key]
        @service_instance = opts[:service_instance]
        @type             = opts[:type] || self.class.type?
      end
      private :initialize

      # opts can have keys
      #   :qualified_key
      #   :id_handle
      def self.aggregate?(diff_sets, opts = {}, &body)
        fail Error::NoMethodForConcreteClass.new(self)
      end
      
      # The arguments gen_hash is canonical hash produced by generation and parse_hash is canonical hash produced by parse 
      # with values being elements of same type
      # Returns a Diff::Set object
      # opts can have keys:
      #  :service_instance
      #  :diff_class
      def self.between_hashes(_gen_hash, _parse_hash, _qualified_key, _opts = {})
        fail Error::NoMethodForConcreteClass.new(self)
      end

      # The arguments gen_array is canonical array produced by generation and parse_array is canonical array produced by parse 
      # with values being elements of same type
      # Returns a Diff::Set object
      # opts can have keys:
      #  :service_instance
      #  :diff_class
      def self.between_arrays(_gen_array, _parse_array, _qualified_key, _opts = {})
        fail Error::NoMethodForConcreteClass.new(self)
      end
      
      # The arguments gen_hash is canonical hash produced by generation and parse_hash is canonical hash produced by parse 
      # with values being elements of same type
      # Returns an array of Diff objects onjust matching keys; does not look for one hash have keys not in otehr hash
      def self.array_of_diffs_on_matching_keys(_gen_hash, _parse_hash, _qualified_key)
        fail Error::NoMethodForConcreteClass.new(self)
      end

      def type
        @type || fail(Error, "Cannot compute type")
      end

      private
      
      def self.type_print_form
        type.to_s
      end      

      def self.type
        type? || fail(Error, "Cannot compute type")
      end

      def self.type?
        split = to_s.split('::')
        if split.size > 2 and split.last == 'Diff'
          split[-2].downcase.to_sym
        end
      end

    end
  end
end
