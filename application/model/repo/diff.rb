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
class DTK::Repo
  class Diff
    Attributes = [:new_file, :renamed_file, :deleted_file, :a_path, :b_path, :diff]
    AttributeAssignFn = Attributes.inject({}) { |h, a| h.merge(a => "#{a}=".to_sym) }
    def initialize(hash_input)
      hash_input.each { |a, v| send(AttributeAssignFn[a], v) }
    end

    def file_added
      @new_file && { path: @a_path }
    end

    def file_renamed
      @renamed_file && { old_path: @b_path, new_path: @a_path }
    end

    def file_deleted
      @deleted_file && { path: @a_path }
    end

    def file_modified
      ((@new_file || @deleted_file || @renamed_file) ? nil : true) && { path: @a_path }
    end

    private

    attr_writer(*Attributes)
  end
end