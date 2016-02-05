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
# This variables need to be set after both defaults and user oevrrides are given
R8::Config[:base_uri] = "http://#{R8::Config[:server_public_dns]}:#{R8::Config[:server_port]}"

# Application paths.., these should be set/written by templating engine on every call
R8::Config[:base_js_uri] = "#{R8::Config[:base_uri]}/js"
R8::Config[:base_js_cache_uri] = "#{R8::Config[:base_uri]}/js/cache"
R8::Config[:base_css_uri] = "#{R8::Config[:base_uri]}/css"
R8::Config[:base_images_uri] = "#{R8::Config[:base_uri]}/images"
R8::Config[:node_images_uri] = "#{R8::Config[:base_uri]}/images/nodeIcons"
R8::Config[:component_images_uri] = "#{R8::Config[:base_uri]}/images/componentIcons"
R8::Config[:avatar_base_uri] = "#{R8::Config[:base_uri]}/images/user_avatars"
R8::Config[:git_user_home] = "/home/#{R8::Config[:repo][:git][:server_username]}"