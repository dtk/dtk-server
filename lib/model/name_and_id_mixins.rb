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
  class Model
    module NameAndIdClassMixin
      def name_to_id(model_handle, name)
        return
        if name.match(/^[0-9]+$/)
          name.to_i
        else
          name_to_id_default(model_handle, name)
        end
      end

      private

      def check_valid_id_default(model_handle, id)
        filter = [:eq, :id, id]
        check_valid_id_helper(model_handle, id, filter)
      end

      def check_valid_id_helper(model_handle, id, filter, opts = {})
        sp_hash = {
          cols: [:id],
          filter: filter
        }
        rows = get_objs(model_handle, sp_hash)
        if rows.empty? && opts[:no_error_if_no_match]
          return nil
        end
        fail ErrorIdInvalid.new(id, pp_object_type()) unless rows.size == 1
        id
      end

      def name_to_id_default(model_handle, name)
        sp_hash =  {
          cols: [:id],
          filter: [:eq, :display_name, name]
        }
        name_to_id_helper(model_handle, name, sp_hash)
      end

      def name_to_id_helper(model_handle, name, augmented_sp_hash, opts = {})
        obj = name_to_object_helper(model_handle, name, augmented_sp_hash, opts)
        obj && obj.id
      end

      def name_to_object_helper(model_handle, name, augmented_sp_hash, opts = {})
        post_filter = augmented_sp_hash.delete(:post_filter)
        augmented_sp_hash[:cols] ||= [:id]

        rows_raw = get_objs(model_handle, augmented_sp_hash)
        rows = (post_filter ? rows_raw.select { |r| post_filter.call(r) } : rows_raw)
        if rows.size == 0
          unless opts[:no_error_if_no_match]
            fail ErrorNameDoesNotExist.new(name, pp_object_type())
          end
        elsif rows.size > 2
          fail ErrorNameAmbiguous.new(name, rows.map { |r| r[:id] }, pp_object_type())
        else
          rows.first
        end
      end

      def model_name_helper(klass, opts = {})
        model_name = Aux.underscore(class_parts(klass).join('')).to_sym
        opts[:no_subclass] ? model_name : concrete_model_name(model_name)
      end

      def class_parts(klass)
        ret = klass.to_s.split('::')
        ret.shift
        ret
      end
    end
  end
end
