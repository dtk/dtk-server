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
module DTK; class Task; class Template
  class Action
    require_relative('action/component_action')
    require_relative('action/action_method')
    require_relative('action/with_method')
    require_relative('action/ad_hoc')
    
    # opts can have keys
    # :index
    # :parent_action
    attr_accessor :index
    def initialize(opts = {})
      @index = opts[:index] || opts[:parent_action] && opts[:parent_action].index
    end
    private :initialize
    
    # opts can have keys
    # :method_name
    # :params
    # :index
    # :parent_action
    def self.create(object, opts = {})
      if object.is_a?(Component)
        add_action_method?(ComponentAction.new(object, opts), opts)
      elsif object.is_a?(Action)
        add_action_method?(object, opts)
      else
        fail Error, "Not yet implemented treatment of action of type {#{object.class})"
      end
    end
    
    def self.find_action_in_list?(serialized_item, node_name, action_list, opts = {})
=begin

      1/29 Vedad

  serialized_item: 
  "kubernetes_local_storage[catapult_node].create_workflow"

  node_name: 
  'catapult_node'

  action_list: ---

  opts: 
  {
               :nodes => [
          [0] {
                        :id => 2147754333,
              :display_name => "catapult_node",
                  :group_id => 2147484269,
                      :type => "node_group_staged"
          },
          [1] {
                        :id => 2147754334,
              :display_name => "mongo",
                  :group_id => 2147484269,
                      :type => "node_group_staged"
          },
          [2] {
                        :id => 2147754335,
              :display_name => "assembly_wide",
                  :group_id => 2147484269,
                      :type => "assembly_wide"
          }
      ],
       :subtask_order => nil,
      :content_params => {
          "kubernetes_local_storage[catapult_node].create_workflow" => {
              :node_group => "catapult_node"
          },
                  "kubernetes_local_storage[mongo].create_workflow" => {
              :node_group => "mongo"
          }
      },
          :retry_node => nil
  }
=end
      ret = nil
      
      parsed             = WithMethod.parse(serialized_item)
      component_name_ref = parsed.component_name_ref
      method_name        = parsed.method_name
      params             = parsed.params
      # require 'byebug'
      # require 'byebug/core'
      # Byebug.wait_connection = true
      # Byebug.start_server('localhost', 5555)
      # debugger
      # if component has external_ref[:type] = 'bash_commands' it means it has bash command instead of puppet in create action
      # here we set bash create action to be executed instead of puppet_apply
      method_name ||= set_bash_create_action(action_list, component_name_ref)
      
=begin
  parsed:
  #<struct XYZ::Task::Template::Action::WithMethod::ParseStruct component_name_ref="kubernetes_local_storage[catapult_node]", method_name="create_workflow", params=nil>
  
  component_name_ref:
  "kubernetes_local_storage[catapult_node]"

  method_name:
  "create_workflow"

  params: nil

=end

      unless action = action_list.find_matching_action(node_name, component_name_ref: component_name_ref)
        #action is nil hence error is raised
        RaiseError.bad_component_name_ref(node_name, parsed) unless opts[:skip_if_not_found]
      else
        if cgn = opts[:component_group_num]
          action = action.in_component_group(cgn)
        end

        action[:retry] = opts[:retry] unless opts[:retry].nil?
        action[:attempts] = opts[:attempts] unless opts[:attempts].nil?
      
        unless method_name
          ret = create(action) 
        else
          action_defs = action[:action_defs] || []
          if action_def = action_defs.find { |ad| ad.get_field?(:method_name) == method_name }
            ret = create(action, action_def: action_def, params: params)
          else
            RaiseError.method_not_defined(parsed, action_defs) unless opts[:skip_if_not_found]
          end
        end
      end

      ret
    end

    def method_missing(name, *args, &block)
      @action.send(name, *args, &block)
    end

    def respond_to?(name)
      @action.respond_to?(name) || super
    end

    def method_name?
      if action_method = action_method?
        action_method.method_name()
      end
    end

    # these can be overwritten
    def action_method?
      nil
    end
    def params?
      nil
    end

    private

    # opts can have keys
    #  :action_def
    #  :params
    def self.add_action_method?(base_action, opts = {})
      if action_def = opts[:action_def] 
        base_action.class::WithMethod.new(base_action, action_def, params: opts[:params])
      else 
        base_action
      end
    end

    def self.set_bash_create_action(action_list, component_name_ref)
      cmp = action_list.find { |a_item| a_item.component_display_name.eql?(component_name_ref.gsub('::', '__')) }
      if cmp && (ext_ref = cmp.external_ref)
        (ext_ref[:type] || '').eql?('bash_commands') ? 'create' : nil
      end
    end

    module RaiseError
      def self.bad_component_name_ref(node_name, parsed)
        err_msg = "The component reference '#{parsed.component_name_ref}' on node '#{node_name}' in the workflow is not in the assembly; either add it to the assembly or delete it from the workflow"
        fail ParsingError, err_msg
      end

      def self.method_not_defined(parsed, action_defs) 
        err_msg = "The action method '#{parsed.method_name}' is not defined on component '#{parsed.component_name_ref}'"
        if action_defs.empty?
          err_msg << '; there are no actions defined on this component.'
        else
          legal_methods = action_defs.map { |ad| ad[:method_name] }
          err_msg << "; legal method names are: #{legal_methods.join(',')}"
        end
        fail ParsingError, err_msg
      end
    end

  end
end; end; end
