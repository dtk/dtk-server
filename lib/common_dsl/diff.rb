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

      # returns object of type Diff::Result  or raises error
      # TODO: DTK-2665: look at more consistently eithr putting error messages on results
      # or throwing errors
      # also look at doing pinpointed violation chaecking leveraging violation code
      def self.process_service_instance(service_instance, module_branch)
        diff_result = Result.new
        unless dsl_file_obj = Parse.matching_service_instance_file_obj?(module_branch)
          fail Error, "Unexpected that 'dsl_file_obj' is nil"
        end
        
        service_instance_parse = dsl_file_obj.parse_content(:service_instance)
        service_instance_gen   = Generate.generate_service_instance_canonical_form(service_instance, module_branch)

        # compute base diffs
        base_diffs = compute_base_diffs?(service_instance, service_instance_parse, service_instance_gen)
        return diff_result unless base_diffs 

        # collate the diffs
        collated_diffs = base_diffs.collate
        return diff_result unless collated_diffs

        dsl_version = service_instance_gen.req(:DSLVersion)
        # TODO: DTK-2665: look at moving setting semantic_diffs because process_diffs can remove items
        #  alternatively have items removed (e.g., create workflow rejected) in compute_base_diffs
        diff_result.semantic_diffs = collated_diffs.serialize(dsl_version)

        process_diffs(diff_result, collated_diffs, module_branch, service_instance_gen, dependent_modules: service_instance_parse[:dependent_modules], service_instance: service_instance)
      end

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

      def self.compute_base_diffs?(service_instance, service_instance_parse, service_instance_gen)
        assembly_gen   = service_instance_gen.req(:Assembly)
        assembly_parse = service_instance_parse # assembly parse and service_instance parse are identical
        assembly_gen.diff?(assembly_parse, QualifiedKey.new, service_instance: service_instance)
      end

      # returns object of type Diff::Result 
      def self.process_diffs(diff_result, collated_diffs, module_branch, service_instance_gen, opts = {})
        DiffErrors.process_diffs_error_handling(diff_result, service_instance_gen) do
          Model.Transaction do
            collated_diffs.process(diff_result, opts)
            DiffErrors.raise_if_any_errors(diff_result)

            # items_to_update are things that need to be updated in repo from what at this point are in object model
            items_to_update = diff_result.items_to_update
            unless items_to_update.empty?
              # Treat updates to repo from object model as transaction that rolls back git repo to what client set it as
              # If error,  RepoUpdate.Transaction wil throw error
              RepoUpdate.Transaction module_branch do
                # update dtk.service.yaml with data from object model
                Generate.generate_service_instance_dsl(opts[:service_instance], module_branch)
                diff_result.repo_updated = true # means repo updated by server
              end
            end
            # for debug
            Aux.stop_for_testing?(:push_diff) 
          end
        end
        diff_result
      end

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
