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
# TODO: deprecate when get all this logic in ModuleLocation::Target
# TODO: putting version defaults in now; may move to seperate file or rename to branch_names_and_versions
module DTK
  VersionFieldDefault = 'master'

  module BranchNamesMixin
    def has_default_version?
      version = update_object!(:version)[:version]
      version.nil? || (version == VersionFieldDefault)
    end

    protected

    def workspace_branch_name(project)
      self.class.workspace_branch_name(project, self[:version])
    end
  end
  module BranchNamesClassMixin
    def version_field_default
      VersionFieldDefault
    end

    def version_field(version = nil)
      version || VersionFieldDefault
    end

    def version_from_version_field(version_field)
      unless version_field == VersionFieldDefault
        ModuleVersion.ret(version_field)
      end
    end

    # TODO: deprecate

    def workspace_branch_name(project, version = nil)
      #      Log.info_pp(["#TODO: ModuleBranch::Location: deprecate workspace_branch_name direct call",caller[0..4]])
      ModuleBranch::Location::Server::Local.workspace_branch_name(project, version)
    end
  end
end