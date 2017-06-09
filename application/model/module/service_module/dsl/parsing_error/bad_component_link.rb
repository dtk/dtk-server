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
module DTK; class ServiceModule; class ParsingError
  class BadComponentLink < self

    private

    def err_params(link_def_ref, base_cmp_name, opts = {})
      ret = Params.new(link_def_ref: link_def_ref, base_cmp_name: base_cmp_name)
      if target_component = opts[:target_component]
        ret.merge!(target_component: target_component)
      end
      ret
    end

    class BadTarget < self
      def initialize(link_def_ref, base_cmp_name, target_component = nil, opts = Opts.new)
        err_params = err_params(link_def_ref, base_cmp_name, target_component: target_component)
        err_msg = "Component '?base_cmp_name' component link '?link_def_ref' refers to a component instance "
        if target_component
          err_msg << "'?target_component' that does not exist"
        else
          err_msg << "that does not exist"
        end
        super(err_msg, err_params, opts)
      end
    end

    class NoLinkDef < self
      def initialize(link_def_ref, base_cmp_name, opts = Opts.new)
        err_params = err_params(link_def_ref, base_cmp_name)
        err_msg = "Undefined component link reference '?link_def_ref' on component '?base_cmp_name'"
        super(err_msg, err_params, opts)
      end
    end
  end
end; end; end
