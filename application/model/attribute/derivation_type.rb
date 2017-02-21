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
  class Attribute
    module DerivationType
      require_relative('derivation_type/non_default')
      module Mixin
        # returns one of [:asserted, :derived__default, :derived__propagated] 
        def derivation_type
          update_object!(:is_instance_value, :value_asserted, :value_derived, :dynamic)
          if self[:is_instance_value]
            :asserted
          elsif self[:value_asserted].nil? and self[:value_derived].nil?
            # TODO: DTK-2906: put in special case for nil value; need to check if we can distinguish this from 
            # :derived__propagated or if not whether it makes a difference
            :derived__default
          elsif !self[:value_asserted].nil?
            :derived__default
          else
            :derived__propagated
          end
        end
      end
    end
  end
end
