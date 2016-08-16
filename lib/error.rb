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
  class Error ##TODO: cleanup; DTK::Error is coming from /home/dtk18/dtk-common/lib/errors/errors.rb
    r8_nested_require('error', 'rest_error')
    r8_nested_require('error', 'usage')
    r8_nested_require('error', 'not_implemented')
    r8_nested_require('error', 'no_method_for_concrete_class')

    # TODO: may deprecate these two below
    r8_nested_require('error', 'not_found')
    r8_nested_require('error', 'amqp')
  end
end
