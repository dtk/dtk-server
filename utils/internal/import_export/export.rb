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
  # class mixin
  module ExportObject
    # target_id_handle_x can either be an id_handle or an array of id_handles
    def export_objects_to_file(target_id_handle_x, json_file, opts = {})
      hash_content =
        if target_id_handle_x.is_a?(Array)
          if target_id_handle_x.size == 1
            hash_content_for_single_target(target_id_handle_x.first, opts)
          else
            target_id_handle_x.inject({}) do |res, target_id_handle|
              content = hash_content_for_single_target(target_id_handle, opts)
              path = target_id_handle[:uri].gsub(Regexp.new('^/'), '').split('/')
              HashObject.set_nested_value!(res, path, content)
              res
            end
          end
        else
          export_objects_to_file_single_target(target_id_handle_x, json_file, opts)
        end
      write_to_file(hash_content, json_file)
    end


    def hash_content_for_single_target(target_id_handle, opts = {})
      target_id_info = get_row_from_id_handle(target_id_handle)
      fail Error.new("Context given (#{target_id_handle}) does not exist") unless target_id_info
      prefix =
        if opts[:prefix_is_top] then '/'
        elsif target_id_info[:uri] =~ %r{(^/.+?/.+?)/.+$} then Regexp.last_match(1)
        elsif target_id_info[:uri] =~ %r{(^/.+/.+$)} then Regexp.last_match(1)
        else fail Error.new
      end
      get_objs_opts = {
        depth: :deep,
        no_hrefs: true,
        no_ids: true,
        # TODO: do we need this? :no_top_level_scalars => true,
        no_null_cols: true,
        fk_as_ref: prefix
      }.merge(opts)
      objects = get_instance_or_factory(target_id_handle, nil, get_objs_opts)

      # stripping off "key" which would be the containing object
      objects.values.first
    end

    def write_to_file(hash_content, json_file)
      f = File.open(json_file, 'w')
      f.puts(JSON.pretty_generate(hash_content))
    rescue Exception => err
      raise Error.new("Error writing exported data to file #{json_file}: #{err}")
    ensure
       f.close
    end
  end
end