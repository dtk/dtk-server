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
  class Aux
    # assumption is that where this included could have a Variations module
    module ParsingingHelper
      module ClassMixin
        def matches?(object, constant)
          unless object.nil?
            variations = variations(constant)
            if object.is_a?(Hash)
              hash_value_of_matching_key?(object, variations)
            elsif object.is_a?(String) || object.is_a?(Symbol)
               variations.include?(object.to_s)
            else
              fail Error.new("Unexpected object class (#{object.class})")
            end
          end
        end

        def hash_subset(hash, *constants)
          constants = constants.flatten(1)
          Aux.hash_subset(hash, constants.flat_map { |constant| variations(constant) }.uniq)
        end

        def matching_key_and_value?(hash, constant)
          variations = variations(constant)
          if matching_key = hash_key_if_match?(hash, variations)
            { matching_key => hash[matching_key] }
          end
        end

        def all_string_variations(*constants)
          constants.flat_map { |constant| variations(constant, string_only: true) }.uniq
        end

        def its_legal_values(constant)
          single_or_set = variations(constant, string_only: true)
          if single_or_set.is_a?(Array)
            "its legal values are: #{single_or_set.join(',')}"
          else
            "its legal value is: #{single_or_set}"
          end
        end

        private

        def variations(constant, opts = {})
          # use of self:: and self. are important because want to evalute wrt to module that pulls this in
          variations = self::Variations.const_get(constant.to_s)
          string_variations = variations.map(&:to_s)
          opts[:string_only] ? string_variations : string_variations + variations.map(&:to_sym)
         rescue
          # if Variations not defined
          # self:: is important beacuse want to evalute wrt to module that pulss this in
          term = self.const_get(constant.to_s)
          opts[:string_only] ? [term.to_s] : [term.to_s, term.to_sym]
        end

        def hash_key_if_match?(hash, variations)
          variations.find { |key| hash.key?(key) }
        end

        def hash_value_of_matching_key?(hash, variations)
          if matching_key = hash_key_if_match?(hash, variations)
            hash[matching_key]
          end
        end
      end
    end
  end
end