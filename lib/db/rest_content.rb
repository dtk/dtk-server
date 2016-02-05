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
module XYZ
  class DB
    module RestContent
      def self.ret_instance_summary(id_info_row, href_prefix, opts = {})
        qualified_ref = id_info_row.ret_qualified_ref()
  link_self = opts[:no_hrefs] ? {} : ret_link(:self, id_info_row[:uri], href_prefix)
        #key, value
        [qualified_ref.to_sym,
         { id: id_info_row[:id], display_name: id_info_row[:display_name] ? id_info_row[:display_name].to_s : qualified_ref }.merge(link_self)]
      end

      def self.ret_link(rel, href_path, href_prefix)
        { link: { rel: rel, href: href_prefix + href_path } }
      end
    end
  end
end