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
#
# Set of methods that expend from Rails ActiveRecord model
#

module DTK
  DTK_C = 2

  module RailsClass
    def all
      get_objs(resolve_mh(), {})
    end

    def create_simple(hash, user)
      create_from_rows(resolve_mh(user), [hash], convert: true, do_not_update_info_table: true)
    end

    def where(sp_hash)
      get_objs(resolve_mh, sp_hash)
    end

    private

    def resolve_mh(user = nil)
      mh = DTK::ModelHandle.new(DTK_C, model_handle_id(), nil, user)
      mh
    end

    def model_handle_id
      clazz_name = self.to_s.split('::').last
      clazz_name.gsub(/(.)([A-Z])/, '\1_\2').downcase
    end
  end
end