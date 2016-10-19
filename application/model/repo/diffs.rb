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
module DTK; class Repo
  class Diffs < Array
    require_relative('diffs/summary')
    attr_reader :a_sha, :b_sha

    def initialize(array_diff_hashes, a_sha, b_sha)
      super(array_diff_hashes.map { |hash| Diff.new(hash) })
      @a_sha = a_sha
      @b_sha = b_sha
    end

    # returns a hash with keys :file_renamed, :file_added, :file_deleted, :file_modified
    def ret_summary
      DiffTypesAndMethods.inject(Summary.new) do |h, (diff_type, diff_method)|
        res = map { |diff| diff.send(diff_method) }.compact
        res.empty? ? h : h.merge(diff_type => res)
      end
    end

    DiffTypesAndMethods = Summary::DiffNames.map { |n| ["files_#{n}".to_sym, "file_#{n}".to_sym] }
  end
end; end
