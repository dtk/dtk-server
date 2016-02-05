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
# TODO: Marked for removal [Haris]
module DTK
  class ComponentController < AuthController
    helper :assembly_helper

    def rest__list
      project           = get_default_project()
      assembly_instance = ret_assembly_instance_object?()

      ignore             = ret_request_params(:ignore)
      hide_assembly_cmps = ret_request_params(:hide_assembly_cmps)

      opts = Opts.new()
      opts.merge?(assembly_instance: assembly_instance)
      opts.merge?(ignore: ignore)
      opts.merge?(hide_assembly_cmps: hide_assembly_cmps) if hide_assembly_cmps

      rest_ok_response Component::Template.list(project, opts)
    end
  end
end