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
module XYZ
  module InputIntoModelClassMixins
    include CommonInputImport
    def input_into_model(container_id_handle, hash_with_assocs, opts_x = {})
      opts = (opts_x[:return_idhs] ? { return_info: true }.merge(opts_x) : opts_x)
      fks = {}
      hash_assigns = remove_fks_and_return_fks!(hash_with_assocs, fks, opts)
      prefixes = update_from_hash_assignments(container_id_handle, hash_assigns)
      ret_global_fks = nil
      unless fks.empty?
        container_id_info = IDInfoTable.get_row_from_id_handle(container_id_handle)
        ret_global_fks = update_with_id_values(fks, container_id_handle[:c], prefixes, container_id_info[:uri], opts)
      end
      if opts[:preserve_input_hash]
        insert_fks_back_in_hash!(hash_with_assocs, fks)
      end

      if opts[:return_info]
        return_info = (opts[:return_idhs] ? return_id_handles(container_id_handle, prefixes) : prefixes)
        [ret_global_fks, return_info]
      else
        ret_global_fks
      end
    end

    # TODO: using mixed forms (ForeignKeyAttr class and "*" form) now to avoid having to convert "*" form when doing an import
    def mark_as_foreign_key(attr, opts = {})
      ForeignKeyAttr.new(attr, opts)
    end

    private

    def return_id_handles(container_id_handle, fully_qual_uris)
      IDInfoTable.get_id_handles_matching_uris(container_id_handle, fully_qual_uris)
    end

    def is_foreign_key_attr?(attr)
      attr.is_a?(ForeignKeyAttr) || (attr.is_a?(String) && attr[0, 1] == '*')
    end

    def foreign_key_attr_form(attr)
      return attr if attr.is_a?(ForeignKeyAttr)
      ForeignKeyAttr.new(attr[0, 1] == '*' ? attr[1, attr.size - 1] : attr)
    end

    class ForeignKeyAttr
      attr_reader :create_ref_object, :attribute
      def initialize(attribute, opts = {})
        @attribute = attribute
        @create_ref_object = opts[:create_ref_object]
      end

      def to_s
        @attribute
      end

      def to_sym
        to_s().to_sym()
      end
    end

    def remove_fks_and_return_fks!(obj, fks, opts = {}, path = '')
      obj.each_pair do |k, v|
        if v.is_a?(Hash)
    remove_fks_and_return_fks!(v, fks, opts, path + '/' + k.to_s)
        elsif v.is_a?(Array)
    next
        elsif is_foreign_key_attr?(k)
    fks[path] ||= {}
    fks[path][foreign_key_attr_form(k)] = modify_uri_with_user_name(v, opts[:username])
    obj.delete(k)
        end
      end
      obj
    end

    def insert_fks_back_in_hash!(hash, fks)
      fks.each do |string_path, fk_info|
        path = string_path.split('/')
        path.shift if path.first.empty?
        assign = fk_info.inject({}) do |h, (fk_attr, v)|
          h.merge("*#{fk_attr.attribute}" => v)
        end
        insert_assign_at_path!(hash, path, assign)
      end
    end

    def insert_assign_at_path!(hash, path, assign)
      first = path.shift
      if hash.key?(first.to_s)
        key = first.to_s
      elsif hash.key?(first.to_sym)
        key = first.to_sym
      else
        fail Error.new("Unexpecetd path element (#{first})")
      end
      if path.empty?
        if hash[key].nil?
          hash[key] = assign
        else
          hash[key].merge!(assign)
        end
      else
        insert_assign_at_path!(hash[key], path, assign)
      end
    end

    def update_with_id_values(fks, c, prefixes, container_uri, opts = {})
      ret_global_fks = nil
      fks.each_pair do |fk_rel_uri_x, info|
        fk_rel_uri = ret_rebased_uri(fk_rel_uri_x, prefixes, container_uri)
        fk_rel_id_handle = IDHandle[c: c, uri: fk_rel_uri]
        info.each_pair do |col, ref_uri_x|
          ref_uri = ret_rebased_uri(ref_uri_x, prefixes, container_uri)
          ref_id_info = get_row_from_id_handle(IDHandle[c: c, uri: ref_uri])
          unless ref_id_info && ref_id_info[:id]
            if col.create_ref_object
              idh = IDHandle[c: c, uri: ref_uri]
              create_simple_instance?(idh, set_display_name: true)
              ref_id_info = get_row_from_id_handle(idh)
            else
              unless opts[:ret_global_fks]
                Log.error("In import_into_model cannot find object with uri #{ref_uri}")
              else
                ret_global_fks ||= {}
                # purposely using fk_rel_uri (rebaselined) but ref_uri_x (raw)
                ret_global_fks[fk_rel_uri] ||= {}
                ret_global_fks[fk_rel_uri][col] = ref_uri_x
              end
              next
            end
          end
          update_instance(fk_rel_id_handle, col.to_sym =>  ref_id_info[:id])
        end
      end
      ret_global_fks
    end

    def process_global_keys(global_fks, c)
      global_fks.each_pair do |fk_rel_uri, info|
      fk_rel_id_handle = IDHandle[c: c, uri: fk_rel_uri]
      info.each_pair do |col, ref_uri|
        ref_id_info = get_row_from_id_handle(IDHandle[c: c, uri: ref_uri])
          unless ref_id_info && ref_id_info[:id]
            if col.create_ref_object
              idh = IDHandle[c: c, uri: ref_uri]
              create_simple_instance?(idh, set_display_name: true)
              ref_id_info = get_row_from_id_handle(idh)
            else
              Log.error("In process_global_keys cannot find object with uri #{ref_uri}")
              next
            end
          end
          update_instance(fk_rel_id_handle, col.to_sym =>  ref_id_info[:id])
        end
      end
    end

    def ret_rebased_uri(uri_x, prefixes, container_uri = nil)
      relation_type_string = stripped_uri = ref = nil
      if uri_x =~ %r{^/(.+?)/(.+?)(/.+$)}
         relation_type_string = Regexp.last_match(1)
         ref = Regexp.last_match(2)
         stripped_uri = Regexp.last_match(3)
      elsif  uri_x =~ %r{^/(.+)/(.+$)}
         relation_type_string = Regexp.last_match(1)
         ref = Regexp.last_match(2)
         stripped_uri = ''
      else
        # TODO: double check that everything that works heer is fine;being no op seems to work fine when uri_x is "" because it is referencing top level object like aproject
        # TODO: raise Error
      end
      # find prefix that matches and rebase
      # TODO: don't think this is exactly right
      prefix_matches = []
      prefixes.each do|prefix|
  prefix =~ %r{^.+/(.+?)/(.+?$)}
  fail Error unless prefix_ref = Regexp.last_match(2)
        prefix_rt = Regexp.last_match(1)
  if relation_type_string == prefix_rt
    if ref == prefix_ref
      return prefix + stripped_uri
   elsif fks_have_common_base(ref, prefix_ref)
           prefix_matches << prefix
          end
        end
      end
      return prefix_matches[0] + stripped_uri if prefix_matches.size == 1
      fail Error.new('not handling case where not exact, but or more prfix matches') if prefix_matches.size > 1
      # if container_uri is non null then uri_x can be wrt container_uri and this is assumed to be the case if reach here
      return container_uri + uri_x if container_uri
      fail Error
    end

    def fks_have_common_base(x, y)
      x =~ Regexp.new('^' + y + '-[0-9]+$') || y =~ Regexp.new('^' + x + '-[0-9]+$')
    end
  end
end
