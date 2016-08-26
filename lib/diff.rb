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
  class Diff
    require_relative('diff/base')
    require_relative('diff/set')
    
    attr_writer :key, :id_handle
    # opts can have keys
    #   :key
    #   :id_handle
    def initialize(opts = {})
      @key        = opts[:key]
      @id_handle  = opts[:id_handle]
    end
    private :initialize
    
    def key
      @key || raise(Error, "Unexpected that @key is nil")
    end
    
    def id_handle
      @id_handle || raise(Error, "Unexpected that @id_handle is nil")
    end
    
    # opts can have keys
    #   :key
      #   :id_handle
    def self.diff?(current_val, new_val, opts = {})
      bass_class.diff?(current_val, new_val, opts)
    end
    
    # opts can have keys
    #   :key
    #   :id_handle
    def self.aggregate?(diff_sets, opts = {})
      set_class.aggregate?(diff_sets, opts)
    end
    
    
    # The arguments gen_hash is canonical hash produced by generation and parse_hash is canonical hash produced by parse 
    # with values being elements of same type
    # Returns a Diff::Set object
    def self.between_hashes(gen_hash, parse_hash)
      set_class.between_hashes(gen_hash, parse_hash)
    end
    
    # The arguments gen_array is canonical array produced by generation and parse_array is canonical array produced by parse 
    # with values being elements of same type
    # Returns a Diff::Set object
    def self.between_arrays(gen_array, parse_array)
      set_class.between_arrays(gen_array, parse_array)
    end
    
    # The arguments gen_hash is canonical hash produced by generation and parse_hash is canonical hash produced by parse 
    # with values being elements of same type
    # Returns an array of Diff objects onjust matching keys; does not look for one hash have keys not in otehr hash
    
    def self.array_of_diffs_on_matching_keys(gen_hash, parse_hash)
      set_class.array_of_diffs_on_matching_keys(gen_hash, parse_hash)
    end
    
    private
    
    def self.bass_class
      kind_of?(Base) ? self : Base
    end
    
    def self.set_class
      kind_of?(Set) ? self : Set
    end
  end
end
