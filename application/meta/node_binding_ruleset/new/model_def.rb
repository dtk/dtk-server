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
{
  schema: :node,
  table: :binding_ruleset,
  columns: {
    type: { type: :varchar, size: 10 }, #|| values:: match || clone
    os_type: { type: :varchar, size: 25 },
    os_identifier: { type: :varchar, size: 50 }, #augments os_type to identify specifics about os. From os_identier given region one can find unique ami
    rules: { type: :json }
  },
  many_to_one: [:library]
}