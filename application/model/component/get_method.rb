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
# TODO: will move get methods that will not be deprecating to here or some file underneath a file directory
module DTK; class Component
  module GetMethod
    module Mixin
      def get_augmented_link_defs
        ndx_ret = {}
        get_objs(cols: [:link_def_links]).each do |r|
          link_def =  r[:link_def]
          pntr = ndx_ret[link_def[:id]] ||= link_def.merge(link_def_links: [])
          pntr[:link_def_links] << r[:link_def_link]
        end
        ret =  ndx_ret.values
        ret.each { |r| r[:link_def_links].sort! { |a, b| a[:position] <=> b[:position] } }
        ret
      end

      def get_node
        get_obj_helper(:node)
      end

      # Only for component instances
      def get_assembly_instance(cols = nil)
        ret = nil
        if assembly_id = get_field?(:assembly_id)
          sp_hash = {
            cols: cols || [:id, :group_id, :display_name],
            filter: [:eq, :id, assembly_id]
          }
          ret = Assembly::Instance.get_objs(model_handle(:assembly_instance), sp_hash).first
        end
        ret || fail(Error, "Unexpected that no assembly associated with component: #{dtk_node.inspect}")
      end

      def get_attributes(opts = {})
        self.class.get_attributes([id_handle], opts)
      end

    end

    module ClassMixin
      def get_include_modules(component_idhs, opts = {})
        get_component_children(component_idhs, IncludeModule, :component_include_module, opts)
      end

      def get_attributes(component_idhs, opts = {})
        get_component_children(component_idhs, ::DTK::Attribute, :attribute, opts)
      end

      def get_implementations(component_idhs)
        ret = []
        return ret if component_idhs.empty?
        mh = component_idhs.first.createMH
        get_objs(mh, sp_hash([:implementation], :id, component_idhs)).map { |r| r[:implementation] }
      end

      private

      # opts can have keys:
      #   :cols - default is common_columns
      #   :cols_plus - addition to cols
      def get_component_children(component_idhs, child_class, child_model_name, opts = {})
        ret = []
        return ret if component_idhs.empty?
        mh = component_idhs.first.create_childMH(child_model_name)
        cols = opts[:cols] || child_class.common_columns
        if cols_plus = opts[:cols_plus]
          cols = (cols + opts[:cols_plus]).uniq
        end
        get_objs(mh, sp_hash(cols, mh.parent_id_field_name, component_idhs))
      end

      def sp_hash(cols, cmp_id_field, component_idhs)
        {
          cols: cols,
          filter: [:oneof, cmp_id_field, component_idhs.map(&:get_id)]
        }
      end
    end
  end
end; end
