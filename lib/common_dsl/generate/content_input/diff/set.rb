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
    class Set < self
      # opts can have keys
      #   :triplet - array with elememts [added, deleted, modified]
      #   :diff_set
      #   :id_handle
      #   :key
      AddElement = Struct.new(:key, :info)
      DeleteElement = Struct.new(:key, :info)
      def initialize(opts = {})
        super(opts)
        # The object attributes are
        #  @added - array, possibly empty, of AddElements
        #  @deleted - array, possibly empty, of DeleteElements
        #  @modified - array, possibly empty, of Diff objects
        if diff_set = opts[:diff_set]
          @added    = diff_set.added
          @deleted  = diff_set.deleted
          @modified = diff_set.modified
        else
          triplet = opts[:triplet] || [[], [], []]
          @added    = triplet[0] || []
          @deleted  = triplet[1] || []
          @modified = triplet[2] || []
        end
      end
      private :initialize
      attr_accessor :added, :deleted, :modified
      
      # The arguments gen_hash is canonical hash produced by generation and parse_hash is canonical hash produced by parse with values being elements of same type
      def self.between_hashes(gen_hash, parse_hash)
        between_arrays_or_hashes(:hash, gen_hash, parse_hash)
      end
      
      # The arguments gen_array is canonical array produced by generation and parse_array is canonical array produced by parse with values being elements of same type
      def self.between_arrays(gen_array, parse_array)
        ndx_gen_array = (gen_array || []).inject({}) { |h, gen_object| h.merge(gen_object.diff_key => gen_object) }
        ndx_parse_array = (parse_array || []).inject({}) { |h, parse_object| h.merge(parse_object.diff_key => parse_object) }
        between_arrays_or_hashes(:array, ndx_gen_array, ndx_parse_array) 
      end
      
      # opts can have keys
      #   :key
      #   :id_handle
      def self.aggregate?(opts = {}, &body)
        diff_set = new(opts)
        # the code passed into body will call diff_set.add?
        # which conditionally adds to @modified
        body.call(diff_set)
        diff_set.modified_empty? ? nil : diff_set
      end
      
      def add?(diff_set_or_array)
        add_to_modified?(diff_set_or_array)
      end
      
      def modified_empty?
        @modified.empty?
      end
      
      def empty?
        @added.empty? and @deleted.empty? and @modified.empty?
      end

      def self.array_of_diffs_on_matching_keys(gen_hash, parse_hash)
        ret = []
        return ret if (gen_hash || {}).empty? or (parse_hash || {}).empty?
        parse_hash.each do |key, parse_object|
          if gen_hash.has_key?(key)
            if diff = gen_hash[key].diff?(parse_object, key)
              ret << diff
            end
          end
        end
        ret
      end
      
      private
      
      def add_to_modified?(diff_set_or_array)
        unless diff_set_or_array.nil? or diff_set_or_array.empty?
          if diff_set_or_array.kind_of?(::Array)
            @modified += diff_set_or_array 
          else
            @modified << diff_set_or_array
          end
        end
      end
      
      def self.between_arrays_or_hashes(array_or_hash, gen_hash, parse_hash)
        added    = []
        deleted  = []
        modified = []
        
        gen_hash   ||= {}
        parse_hash ||= {}
        
        parse_hash.each do |key, parse_object|
          if gen_hash.has_key?(key)
            if diff = gen_hash[key].diff?(parse_object, key)
              modified << diff
            end
          else
            added << AddElement.new(key, parse_object)
            end
        end
        
        gen_hash.each do |key, gen_object|
          unless gen_object.ignore_for_diff_to_parse?
            deleted << DeleteElement.new(key, gen_object) unless parse_hash.has_key?(key)
          end
        end
          
        case array_or_hash
        when :hash
          new(:triplet => [added, deleted, modified])
        when :array
          new(:triplet => [added.values, deleted.values, modified.values])
        end
      end
      
    end
  end
end; end


