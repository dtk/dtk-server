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
  class AttributeLink
    class IndexMap < Array
      def merge_into(source, output_var)
        self.inject(source) do |ret, el|
          delta = el[:output].take_slice(output_var)
          el[:input].merge_into(ret, delta)
        end
      end

      def self.convert_if_needed(x)
        x.is_a?(Array) ? create_from_array(x) : x
      end

      def self.generate_from_paths(input_path, output_path)
        create_from_array([{ input: input_path, output: output_path }])
      end

      def self.generate_from_bounds(lower_bound, upper_bound, offset)
        create_from_array((lower_bound..upper_bound).map { |i| { output: [i], input: [i + offset] } })
      end

      # TODO: may be able to be simplified because may only called be caleld with upper_bound == 0
      def self.generate_for_output_scalar(upper_bound, offset)
        create_from_array((0..upper_bound).map { |i| { output: [], input: [i + offset] } })
      end

      def self.generate_for_indexed_output(output_index)
        create_from_hash(output: [output_index], input: [])
      end

      def input_array_indexes
        ret = []
        map do |el|
          fail Error.new('unexpected form in input_array_indexes') unless el[:input].is_singleton_array?()
          el[:input].first
        end
      end

      def self.resolve_input_paths!(index_map_list, component_mh)
        return if index_map_list.empty?
        paths = []
        index_map_list.each { |im| im.each { |im_el| paths << im_el[:input] } }
        Path.resolve_paths!(paths, component_mh)
      end

      private

      def self.create_from_hash(hash)
        create_from_array([hash])
      end

      def self.create_from_array(array)
        return nil unless array
        ret = new()
        array.each do |el|
          input = el[:input].is_a?(Path) ? el[:input] : Path.create_from_array(el[:input])
          output = el[:output].is_a?(Path) ? el[:output] : Path.create_from_array(el[:output])
          ret << { input: input, output: output }
        end
        ret
      end

      class Path < Array
        def is_singleton_array?
          self.size == 1 && is_array_el?(self.first)
        end
        
        def take_slice(source)
          return source if self.empty?
          return nil if source.nil?
          el = self.first
          if is_array_el?(el)
            if source.is_a?(Array)
              rest().take_slice(source[el])
            else
              Log.error('array expected')
              nil
          end
          else
            if source.is_a?(Hash)
              rest().take_slice(source[el.to_s])
            else
              Log.error('hash expected')
              nil
            end
          end
        end
        
        def merge_into(source, delta)
          return delta if self.empty?
          el = self.first
          if is_array_el?(el)
            if source.is_a?(Array) || source.nil?()
              ret = source ? source.dup : []
              if ret.size <= el
                ret += (0..el - ret.size).map { nil }
              end
              ret[el] = rest().merge_into(ret[el], delta)
              ret
            else
              Log.error('array expected')
              nil
            end
          else
            if source.is_a?(Hash) || source.nil?()
              ret = source || {}
              ret.merge(el.to_s => rest().merge_into(ret[el.to_s], delta))
            else
              Log.error('hash expected')
              nil
            end
          end
        end
        
        # TODO: more efficient and not needed if can be resolved when get index
        def self.resolve_paths!(path_list, component_mh)
          ndx_cmp_idhs = {}
          path_list.each do |index_map_path|
            index_map_path.each_with_index do |el, i|
              next unless el.is_a?(Hash)
              next unless id = (el[:create_component_index] || {})[:component_id]
              ndx_cmp_idhs[id] ||= { idh: component_mh.createIDH(id: id), elements: [] }
              ndx_cmp_idhs[id][:elements] << { path: index_map_path, i: i }
            end
          end
          return if ndx_cmp_idhs.empty?
          cmp_idhs =  ndx_cmp_idhs.values.map { |x| x[:idh] }
          sp_hash = { cols: [:id, :multiple_instance_ref] }
          opts = { keep_ref_cols: true }
          cmp_info = Model.get_objects_in_set_from_sp_hash(cmp_idhs, sp_hash, opts)
          cmp_info.each do |r|
            ref = r[:multiple_instance_ref]
            ndx_cmp_idhs[r[:id]][:elements].each do |el|
              el[:path][el[:i]] = ref
            end
          end
        end
        
        private
        
        def self.create_from_array(a)
          ret = new()
          return ret unless a
          a.each do |el|
            if el.is_a?(String) && el =~ /^[0-9]+$/
              el = el.to_i
            end
          ret << el
          end
          ret
        end
        
        def rest
          self[1..self.size - 1]
        end
        
        def is_array_el?(el)
          el.is_a?(Fixnum)
        end

      end
    end
  end
end