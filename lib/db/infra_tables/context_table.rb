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
  class ContextTable
    class << self
      # TBD: may have parent class for infra tables
      def set_db(db)
        @db = db
      end

  ###### SchemaProcessing
  def create?
          @db.create_schema?(CONTEXT_TABLE[:schema])

    @db.create_table? CONTEXT_TABLE do
      primary_key :id #TBD: more columns will be put in
          end
        end
        ###### end: SchemaProcessing

        ###### DataProcessing
        def create_default_contexts?
    #TBD : hard coding contexts 1 and 2
    [1, 2].each do|id|
      context_ds().insert(id: id) if context_ds().where(id: id).empty?
          end
  end

      private

        def context_ds
    @db.dataset(CONTEXT_TABLE)
        end
      ###### end: DataProcessing
    end
  end
end