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
# TODO: incomplete; when refactored to use adapter structure; structure looked like mock used all same as grit except for clone branch
require 'fileutils'
module DTK; class RepoManager
  class Mock < self
    def self.create(path, branch, opts = {})
      new(path, branch, opts)
    end
    def initialize(path, branch, _opts = {})
      fail Error.new("mock mode only supported when branch=='master'") unless  branch == 'master'
      root = R8::Config[:repo][:base_directory]
      @path = "#{root}/#{path}"
    end

    def get_file_content(file_asset)
      Dir.chdir(@path) { File.open(file_asset[:path]) { |f| f.read } }
    end

    def self.repo_url
    end
    def self.repo_server_dns
    end

    def self.create_repo_clone(repo_obj, opts)
      local_repo_dir = repo_obj[:local_dir]
      repo_name = repo_obj[:repo_name]
      if File.exist?(local_repo_dir)
        if opts[:delete_if_exists]
          FileUtils.rm_rf local_repo_dir
        else
          fail Error.new("trying to create a repo (#{repo_name}) that exists already on r8 server")
        end
      end
    end

    # no ops if dont explicitly have method
    class << self
      def method_missing(_meth, *_args, &_block)
        nil
      end
    end
    def method_missing(_meth, *_args, &_block)
      nil
    end
  end
end; end
