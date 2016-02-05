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
  class ModuleDSL
    class ParsingError
      class Dependency < self
        def self.create(msg, dep_choice, *args)
          dep = (dep_choice.respond_to?(:print_form) ? dep_choice.print_form() : dep_choice)
          hash_params = {
            base_cmp: dep_choice.base_cmp_print_form(),
            dep_cmp: dep_choice.dep_cmp_print_form(),
            dep: dep
          }
          create_with_hash_params(msg, hash_params, *args)
        end
      end
    end
  end
end