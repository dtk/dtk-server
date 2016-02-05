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
module DTK; class NodeModuleDSL
  module UpdateModelMixin
    def update_model(_opts = {})
      pp [:info_to_insert, @input_hash]
      Log.info('Here code is written that inserts that contents of @input_hash into objects of the form node_image')
      fail ErrorUsage.new('got here; place where objects must be inserted')
      # TODO:
      # db_update_hash = ...
      #TODO: : this would do teh actual db insert
      # Model.input_hash_content_into_model(@project_idh,db_update_hash)
    end
  end
end; end