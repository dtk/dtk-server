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
module DTK
  class NodeComponent::IAAS
    class Ec2
      module ClientToken
        extend Mixin 

        def self.generate
          time_part = generate_time_part
          if @last_time == time_part
            @num += 1
          else
            @num = 1
          end
          @last_time = time_part
          
          "#{tenant}-#{user}-#{time_part}-#{@num}"
        end
        
        private
        
        def self.generate_time_part
          Time.now.to_f.to_s.gsub(/\./, '-')
        end
        
      end
    end
  end
end
