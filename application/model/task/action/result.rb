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
  class Task::Action
    class Result < HashObject
      def initialize(hash = {})
        super(hash)
        self[:result_type] = Aux.demodulize(self.class.to_s).downcase
      end
      
      class Succeeded < self
        def initialize(hash = {})
          super(hash)
        end
      end

      class Failed < self
        def initialize(error)
          super()
          self[:error] =  error.to_hash
        end
      end

      class Cancelled < self
        def initialize(hash = {})
          super(hash)
        end
      end

    end
  end
end
