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
module DTK; class Node
  class Type
    class Node < self
      Types =
        [
         :stub,              # - in an assembly template
         :image,             # - corresponds to an IAAS, hyperviser or container image
         :instance,          # - in a service instance where it correspond to an actual node
         :staged,            # - in a service instance before actual node correspond to it
         :target_ref,        # - target_ref to actual node
         :target_ref_staged, # - target_ref to node not created yet
         :physical,          # - target_ref that corresponds to a physical node
         :assembly_wide      # - assembly_wide node hidden from context
        ]
      Types.each do |type|
        class_eval("def self.#{type}(); '#{type}'; end")
      end

      def self.types
        Types
      end

      StagedTypes = [:staged,:target_ref_staged]
      def self.is_staged?(type)
        StagedTypes.include?(type.to_sym)
      end
    end
  end
end; end