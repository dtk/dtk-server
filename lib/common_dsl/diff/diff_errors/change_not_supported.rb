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
module DTK
  class CommonDSL::Diff::DiffErrors
    class ChangeNotSupported < self
      # opts can have keys
      #   :create_backup_file (Boolean)
      def initialize(diff_element, opts = {})
        super(opts.merge(error_msg: change_msg(diff_element)))
      end
      
      private
      
      DEFAULT_CHANGE_VERB = 'Changing'
      def change_msg(diff_element)
        type_and_op = diff_element.diff_type_and_operation
        object_type = type_and_op.object_type
        object_term = object_type.nil? ? 'an object' : "an object of type '#{object_type}'"
        change_verb = CHANGE_VERB_MAPPING[type_and_op.operation] || DEFAULT_CHANGE_VERB
        
        "#{change_verb} #{object_term} is not supported"
      end 
      
      CHANGE_VERB_MAPPING = {
        add: 'Adding',
        delete: 'Deleting',
        modify: 'Modifying',
      }

    end
  end
end
