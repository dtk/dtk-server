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
module DTK; class AttributeLink
  class UpdateDelta < HashObject
    require_relative('update_delta/delete')
    require_relative('update_delta/simple')
    require_relative('update_delta/array_append')
    require_relative('update_delta/indexed_output')
    require_relative('update_delta/partial')

    def self.update_attributes_and_index_maps(attr_mh, update_deltas, opts = {})
      critical_section { update_in_critical_section(attr_mh, update_deltas, opts) }
    end

    # aug_attr_links is an array of attribute links (where a specfic one can appear multiple times
    # aug_attr_links has the dangling link info
    # it is augmented with
    # :input_attribute - attribute that is on input side of attribute link
    # :other_input_link - an atribute link that connects to :input_attribute attribute; can refer to same
    # link as self does
    #
    # TODO: may change name to reflect this can update index_maps
    def self.update_for_delete_links(attr_mh, aug_attr_links, opts = {})
      ret = []
      links_delete_info = Delete.links_delete_info(aug_attr_links)
      return ret if links_delete_info.empty?
      
      # find updated attributes
      updated_attrs = critical_section { links_delete_info.map { |link_info| Delete.update_attribute(attr_mh, link_info) } } 
      
      # propagate these changes; if opts[::add_state_changes] then produce state changes
      Attribute.propagate_and_optionally_add_state_changes(attr_mh, updated_attrs, opts)
    end

    private

    Lock = Mutex.new
    def self.critical_section
      ret = nil
      Lock.synchronize { ret = yield }
      ret
    end

    def self.update_in_critical_section(attr_mh, update_deltas, opts = {})
      # break up by type of row and process and aggregate
      return [] if update_deltas.empty?
      ndx_update_deltas = update_deltas.inject({}) do |h, r|
        index = r.class
        (h[r.class] ||= []) << r
        h
      end
      ndx_update_deltas.map do |type, rows|
        update_aux(type, attr_mh, rows, opts)
      end.flatten
    end

    def self.update_aux(update_delta_class, attr_mh, update_deltas, opts = {})
      update_derived_source(attr_mh, update_deltas)

      if update_delta_class.respond_to?(:update_attribute_values)
        update_delta_class.update_attribute_values(attr_mh, update_deltas, opts)
      else
        Simple.update_attribute_values(attr_mh, update_deltas, opts)
      end
    end

    def self.update_derived_source(attr_mh, update_deltas)
      Attribute::PropagateChanges::DerivedSource.update_from_propagated(attr_mh, update_deltas)
    end

    def self.input_index(link_hash)
      input_output_index_aux(link_hash, :input)
    end
    def input_index(link_hash)
      self.class.input_index(link_hash)
    end

    def self.output_index(link_hash)
      input_output_index_aux(link_hash, :output)
    end
    def output_index(link_hash)
      self.class.output_index(link_hash)
    end

    def self.input_output_index_aux(link_hash, dir)
      ret = nil
      unless index_map = link_hash[:index_map]
        return ret
      end
      unless index_map.size == 1
        Log.error("not treating update_for_delete_link when index_map size is not equal to 1; its value is #{index_map.inspect}")
        return ret
      end
      index_map.first && index_map.first[dir]
    end
  end
end; end
