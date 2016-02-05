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

require 'chef/rest'
require 'mixlib/authentication'
module XYZ
  class ChefProcessor
    # instance mixin
    module ChefServerConnection
      def initialize_chef_connection(_chef_server_uri) #TBD: chef_server_uri is stub
        Chef::Config.from_file('/etc/chef/client.rb') #TBD: stub; will replace by passing in relavant paramters
        Chef::Log.level(ENV.key?('LOG_LEVEL') ? ENV['LOG_LEVEL'].to_sym : Chef::Config[:log_level])
        Mixlib::Authentication::Log.logger = Chef::Log.logger

        Chef::Config[:node_name] = 'chef-webui' #TDB: stub until pass in auth
        Chef::Config[:client_key] = '/etc/chef/webui.pem'
        @rest = Chef::REST.new(Chef::Config[:chef_server_url], Chef::Config[:node_name], Chef::Config[:client_key])
      end

      def get_rest(item)
        @rest.get_rest(item)
      end
    end
  end
end