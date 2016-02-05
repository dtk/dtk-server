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
  class ExternalDependencies < Hash
    def initialize(hash = {})
      super()
      replace(pruned_hash(hash)) unless hash.empty?
    end
    KeysProblems = [:inconsistent, :possibly_missing, :ambiguous]
    KeysOk = [:component_module_refs]
    KeysAll = KeysProblems + KeysOk

    def any_errors?
      !!KeysProblems.find { |k| has_data?(self[k]) }
    end

    def ambiguous?
      self[:ambiguous]
    end

    def possibly_missing?
      self[:possibly_missing]
    end

    def pruned_hash(hash)
      ret = {}
      KeysAll.each do |k|
        v = hash[k]
        ret.merge!(k => v) if has_data?(v)
      end
      ret
    end

    private

    def has_data?(val)
      !val.nil? && (!val.is_a?(Array) || !val.empty?())
    end
  end
end