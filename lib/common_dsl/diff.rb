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
      require_relative('diff/element')

      require_relative('diff/base')
      require_relative('diff/set')

      def self.process_service_instance(service_instance, module_branch)
        diff_result = Result.new
        unless dsl_file_obj = Parse.matching_service_instance_file_obj?(module_branch)
          fail Error, "Unexpected that 'dsl_file_obj' is nil"
        end
        service_instance_parse = dsl_file_obj.parse_content(:service_instance)
        service_instance_gen   = Generate.generate_service_instance_canonical_form(service_instance, module_branch)

        if base_diffs = compute_base_diffs(service_instance, service_instance_parse, service_instance_gen)
          if collated_diffs = base_diffs.collate
            dsl_version = service_instance_gen.req(:DSLVersion)
# for debug
#File.open('/tmp/raw', 'w') {|f| PP.pp(base_diffs, f) }
#File.open('/tmp/collated', 'w') {|f| PP.pp(collated_diffs, f) }
STDOUT << YAML.dump(collated_diffs.serialize(dsl_version: dsl_version))
            Model.Transaction do
              collated_diffs.process(diff_result)
              pp [:diff_result, diff_result]
Aux.stop_for_testing?(:push_diff) # TODO: for debugging
              Model.RollbackTransaction if ret.any_errors?
            end
            diff_result
          end
        end  
      end

      # opts can have keys
      #   :qualified_key
      #   :id_handle
      def self.diff?(current_val, new_val, opts = {})
        bass_class.diff?(current_val, new_val, opts)
      end
      
      def self.aggregate?(diff_sets)
        set_class.aggregate?(diff_sets)
      end
      
      # The arguments gen_hash is canonical hash produced by generation and parse_hash is canonical hash produced by parse 
      # with values being elements of same type
      # Returns a Diff::Set object
      def self.between_hashes(gen_hash, parse_hash, qualified_key)
        set_class.between_hashes(gen_hash, parse_hash, qualified_key)
      end
      
      # The arguments gen_array is canonical array produced by generation and parse_array is canonical array produced by parse 
      # with values being elements of same type
      # Returns a Diff::Set object
      def self.between_arrays(gen_array, parse_array, qualified_key)
        set_class.between_arrays(gen_array, parse_array,qualified_key)
      end
      
      # The arguments gen_hash is canonical hash produced by generation and parse_hash is canonical hash produced by parse 
      # with values being elements of same type
      # Returns an array of Diff objects onjust matching keys; does not look for one hash have keys not in otehr hash
      
      def self.array_of_diffs_on_matching_keys(gen_hash, parse_hash, qualified_key)
        set_class.array_of_diffs_on_matching_keys(gen_hash, parse_hash, qualified_key)
      end

      def type
        self.class.type
      end

      private

      def self.compute_base_diffs(service_instance, service_instance_parse, service_instance_gen)
        assembly_gen   = service_instance_gen.req(:Assembly)
        assembly_parse = service_instance_parse # assembly parse and service_instance parse are identical
        assembly_gen.diff?(assembly_parse, QualifiedKey.new, service_instance: service_instance)
      end

      def self.type_print_form
        type.to_s
      end      

      def self.type
        split = to_s.split('::')
        unless split.size > 2 and split.last == 'Diff'
          fail Error, "Unexpected class fomat: #{self}" 
        end
        split[-2].downcase.to_sym
      end

      def self.bass_class
        kind_of?(Base) ? self : Base
      end
      
      def self.set_class
        kind_of?(Set) ? self : Set
      end
    end
  end
end
