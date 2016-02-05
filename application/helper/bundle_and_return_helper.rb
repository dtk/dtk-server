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
module Ramaze::Helper
  module BundleAndReturnHelper
    class ControllerResults < Hash
    end

    class ControllerResultsRest < ControllerResults
      def initialize(result)
        replace(result)
      end
    end

    class ControllerResultsWeb < ControllerResults
      def initialize
        super
        replace(as_run_list: [])
      end

      def add(action_namespace, ctrl_result)
        self[action_namespace] = ctrl_result
        self[:as_run_list] << action_namespace
      end
    end

    def include_css(css_name)
      @css_includes << R8::Config[:base_css_uri] + '/' + css_name + '.css'
    end

    # TODO: augment with priority param when necessary
    def include_js(js_name)
      @js_includes << R8::Config[:base_js_uri] + '/' + js_name + '.js'
    end

    def include_js_tpl(js_tpl_name)
      @js_includes << R8::Config[:base_js_uri] + '/cache/' + js_tpl_name
    end

    def add_js_exe(js_content)
      @js_exe_list << js_content
    end

    def run_javascript(js_content)
      @js_exe_list << js_content
    end

    def ret_js_includes
      includes_ret = @js_includes
      @js_includes = []
      includes_ret
    end

    def ret_css_includes
      includes_ret = @css_includes
      @css_includes = []
      includes_ret
    end

    def ret_js_exe_list
      exe_list = @js_exe_list
      @js_exe_list = []
      exe_list
    end
    ######
  end
end