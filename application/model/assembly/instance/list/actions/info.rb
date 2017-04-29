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
  module Assembly::Instance::List
    class Actions
      class Info
        # opts can have keys:
        #   :node
        #   :node_name
        #   :node_group_range
        def initialize(component_type, component_title, method_name, opts = {})
          @component_type        = component_type
          @component_title       = component_title
          @method_name           = method_name
          @action_type           = ret_action_type(method_name)
          @node_name, @node_ref  = ret_node_name_and_ref(opts) 
        end
        attr_reader :component_type, :component_title, :method_name, :node_name

        def display_form
          display_name = ''
          display_name << "#{node_ref}/" unless node_ref.nil?
          display_name << component_type
          display_name << "[#{component_title}]" if component_title
          display_name << ".#{method_name}" unless is_create_method?
          { display_name: display_name, action_type: action_type }
        end
        
        def self.display_form(action_info_array)
          ret = []
          index_iterate(action_info_array) do |node_name, component_type, method_name, action_info_array|
            info_element = 
              if action_info_array.size == 1
                action_info_array.first
              else
                # everything wil be same in action_info_array elements except for title
                sample_info = action_info_array.first
                new(component_type, title_summary(action_info_array), method_name, node: sample_info.node) 
              end
            ret << info_element.display_form
          end
          ret
        end

        private
        
        attr_reader :action_type, :node_ref
        
        CREATE_METHOD = 'create'
        TITLE_SUMMARY = 'NAME'
        COUNT_TO_USE_TITLE_SUMMARY = 4
        MAX_NODE_GROUP_MEMBERS_TO_DISPLAY = 2
        TITLE_DELIM = ','

        def self.title_summary(action_info_array)
          if action_info_array.size > COUNT_TO_USE_TITLE_SUMMARY
            TITLE_SUMMARY
          else
            action_info_array.map(&:component_title).join(TITLE_DELIM) 
          end
        end
        
        def self.index_iterate(action_info_array, &block)
          index_action_info(action_info_array).each_pair do |node_name, ndx_by_component_type|
            ndx_by_component_type.each_pair do |component_type, ndx_by_method_name|
              ndx_by_method_name.each_pair do |method_name, action_info_array|
                block.call(node_name, component_type, method_name, action_info_array)
              end
            end
          end
        end
      
        # indexed by [node_name][component_type][method_name]
        def self.index_action_info(action_info_array)
          ret = {}
          action_info_array.each do |action_info|
            node_name      = action_info.node_name
            component_type = action_info.component_type
            method_name    = action_info.method_name || CREATE_METHOD
            (((ret[node_name] ||= {})[component_type] ||= {})[method_name] ||= []) << action_info
          end
          ret
        end

        # opts can have keys:
        #   :node
        #   :node_name
        #   :node_group_range
        # returns [node_name, node_ref]
        def ret_node_name_and_ref(opts = {}) 
          unless opts[:node] or (opts[:node_name] and opts[:node_group_range])
            fail Error, "opts[:node] or (opts[:node_name] and opts[:node_group_range] must be non nil"
          end

          node_name = node_ref = nil
          if node = opts[:node]
            node_name = node.node_component_ref
            node_ref  = node_name unless node.is_assembly_wide_node?
          else
            range = opts[:node_group_range]

            node_name = opts[:node_name]
            node_ref  = "#{node_name}:[#{range[0]}-#{range[1]}]"
          end
          [node_name, node_ref]
        end
        
        def ret_method_name_ref(method_name)
          method_name unless is_create_method?(method_name)
        end

        def ret_action_type(method_name)
          is_create_method?(method_name) ? 'component_create' : 'component_action'
        end

        def is_create_method?(method_name = nil)
          method_name ||= @method_name
          method_name.nil? or method_name == CREATE_METHOD
        end
        
      end
    end
  end
end  

