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
module DTK; class Task
  module CreateClassMixin
    def create_from_assembly_instance?(assembly, opts = {})
      ret = nil
      unless task = Create.create_from_assembly_instance?(assembly, opts)
        return ret
      end
      task[:breakpoint] = opts[:breakpoint] if opts[:breakpoint]
      #alters task if needed to decompose node groups into node
      # require 'byebug'
      # require 'byebug/core'
      # Byebug.wait_connection = true
      # Byebug.start_server('localhost', 5555)
      # debugger
      NodeGroupProcessing.decompose_node_groups!(task)
    end

    def create_for_ad_hoc_action(assembly, component_idh, opts = {})
      task = Create.create_for_ad_hoc_action(assembly, component_idh, opts)
      ret = NodeGroupProcessing.decompose_node_groups!(task, opts)

      # raise error if any its nodes are not running
      not_running_nodes = NodeComponent.node_components(ret.get_associated_nodes, assembly).select { |node_component| ! node_component.node_is_running? }.map(&:node)
      unless not_running_nodes.empty?
        node_is = (not_running_nodes.size == 1 ? 'node is' : 'nodes are')
        node_names = not_running_nodes.map(&:display_name).join(', ')
        fail ErrorUsage.new("Cannot execute the action because the following #{node_is} not running: #{node_names}")
      end
      ret
    end

    def create_top_level(task_mh, assembly, opts = {})
      Create.create_top_level_task(task_mh, assembly, opts)
    end

    def create_for_delete_from_database(assembly, component, node, opts = {})
      task = Create.create_for_delete_from_database(assembly, component, node, opts)
      return task if opts[:return_executable_action]
      # ret = NodeGroupProcessing.decompose_node_groups!(task, opts)

      unless opts[:skip_running_check]
        # raise error if any its nodes are not running
        not_running_nodes = task.get_associated_nodes().select { |n| n.get_and_update_operational_status!() != 'running' }
        unless not_running_nodes.empty?
          node_is = (not_running_nodes.size == 1 ? 'node is' : 'nodes are')
          node_names = not_running_nodes.map(&:display_name).join(', ')
          fail ErrorUsage.new("Cannot execute the action because the following #{node_is} not running: #{node_names}")
        end
      end

      task
    end

    def create_for_command_and_control_action(assembly, action, params, node, opts = {})
      task = Create.create_for_command_and_control_action(assembly, action, params, node, opts)
      return task if opts[:return_executable_action]
      NodeGroupProcessing.decompose_node_groups!(task, opts)
    end

    def get_delete_workflow_order(assembly, opts = {})
      target_idh = target_idh_from_assembly(assembly)
      task_mh    = target_idh.create_childMH(:task)

      if opts[:uninstall]
        return get_reversed_create_workflow_order(assembly)
      end
      task_template_content = nil
      begin
        task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly, :node_centric], assembly, { task_action: 'delete', serialized_form: opts[:serialized_form] })
      rescue Task::Template::ParsingError => e
        return nil
      rescue Task::Template::TaskActionNotFoundError => e
        opts.merge!(uninstall: true)
        return get_reversed_create_workflow_order(assembly)
      end
      component_order_from_task_template_content(:delete, task_template_content)
    end

    private
      
    def component_order_from_task_template_content(type, task_template_content)
      if serialization_form = task_template_content && task_template_content.serialization_form
        if !serialization_form[:subtasks].nil? && serialization_form[:subtasks].length > 1
          (serialization_form[:subtasks] || []).inject([]) { |a, subtask| a + subtype_component_types(type, subtask) }
        else
          subtasks_from_serialization_form(serialization_form).inject([]) { |a, subtask| a + subtype_component_types(type, subtask) }
        end
      end
    end
  
    def subtasks_from_serialization_form(serialization_form)
      if serialization_form[:subtasks]
        serialization_form[:subtasks]
      elsif COMPONENT_OR_ACTION_KEYS[:delete].find { | key| serialization_form.has_key?(key) }
        # serialization_form has a single action or component
        [serialization_form]
      else
        []
      end
    end

    def get_reversed_create_workflow_order(assembly)
      if task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly, :node_centric], assembly)
        if create_order = component_order_from_task_template_content(:create, task_template_content)
          create_order.reverse.uniq
        end
      end
    end

    # TODO: DTK-3010; this is hack for DTK-3010; want to call parsing logic
    COMPONENT_OR_ACTION_KEYS = {
      delete: [:ordered_components, :components, :actions, :component, :action],
      create: [:ordered_components, :components, :component, :actions]
    }
    def subtype_component_types(type, subtask)
      keys = COMPONENT_OR_ACTION_KEYS[type]
      if matching_key = keys.find { |key| subtask.has_key?(key) }
        component_or_actions = subtask[matching_key]
        component_or_actions = [component_or_actions] unless component_or_actions.kind_of?(::Array)
        component_or_actions.map do |item|
          # convert to component type form and strip off action
          item.gsub('::', '__').gsub(/\.[^\.]+$/, '')
        end
      else
        []
      end
    end
  end

  class Create
    r8_nested_require('create', 'nodes_task')

    def self.create_for_ad_hoc_action(assembly, component, opts = {})
      ad_hoc_action = Template::Action::AdHoc.new(assembly, component, opts)
      task_action_name = ad_hoc_action.task_action_name()
      task_template_content = ad_hoc_action.task_template_content

      # TODO: below needs to use action params if they exist
      task_mh = target_idh_from_assembly(assembly).create_childMH(:task)
      subtasks = task_template_content.create_subtask_instances(task_mh, assembly.id_handle())
      #create_top_level_task(task_mh, assembly, task_action: task_action_name).add_subtasks(subtasks)
      create_top_level_task(task_mh, assembly, task_action: task_action_name, retry: component[:retry], task_params: opts[:task_params]).add_subtasks(subtasks)
    end

    def self.create_for_workflow_action(assembly, task_info, full_workflow)
      # require 'byebug'
      # require 'byebug/core'
      # Byebug.wait_connection = true
      # Byebug.start_server('localhost', 5555)
      # debugger
      component_type = :service
      target_idh     = target_idh_from_assembly(assembly)
      task_mh        = target_idh.create_childMH(:task)

      nodes_to_create, nodes_wait_for_start = nodes_to_process_in_task(assembly, Aux.hash_subset({}, [:start_nodes, :ret_nodes_to_start]))

      unless nodes_wait_for_start.empty?
        node_scs = StateChange::Assembly.node_state_changes(:wait_for_node, assembly, target_idh, just_leaf_nodes: true, nodes: nodes_wait_for_start)
        start_nodes_task = NodesTask.create_subtask(Action::PowerOnNode, task_mh, node_scs)
      end
      create_nodes_task = nil

      opts = {component_type_filter: component_type, task_action: task_info[:top_task_display_name], breakpoint: task_info[:breakpoint]}
     
      # opts[:full_workflow] = full_workflow
      # opts[:nodes_to_create] = nodes_to_create
      opts[:nodes]             = assembly.get_nodes
      task_template_content    = Template::ConfigComponents.get_or_generate_template_content([:assembly, :node_centric], assembly, opts)
      #  require 'byebug'
      # require 'byebug/core'
      # Byebug.wait_connection = true
      # Byebug.start_server('localhost', 5555)
      # debugger

      stages_config_nodes_task = task_template_content.create_subtask_instances(task_mh, assembly.id_handle())

=begin
Giving context with an example that I am trapping in executing a small workflow. Most of this is for context and code can be used without changing. 

Starting to trap at
17, 26] in /home/dtk1/server/current/application/model/task/create.rb
=> 22:       unless task = Create.create_from_assembly_instance?(assembly, opts)
I descend into Create.create_from_assembly_instance?
and trap and step into Template::ConfigComponents.get_or_generate_template_content
[235, 250] in /home/dtk1/server/current/application/model/task/create.rb
=> 235:       task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly, :node_centric], assembly, opts_tt)

Yu cand see comment in code
[112, 121] in /home/dtk1/server/current/application/model/task/template/config_components.rb
   112:
   113:       # action_types is scalar or array with elements
   114:       # :assembly
   115:       # :node_centric

Node_centric is legacy so everything we deal with is :assembly type

   120:         task_action = opts[:task_action]
task_action is create since I executed teh task action workflow

An important method to explain is ActionList::ConfigComponents
[117, 126] in /home/dtk1/server/current/application/model/task/template/config_components.rb
=> 122:         cmp_actions = ActionList::ConfigComponents.get(assembly, opts_action_list)
and descend into this method. Now waht it returns is an array where an example element is show below. This action list is generated so that when tarsnforming teh workflow we have detailed information about each component being executed
#<XYZ::Task::Template::Action::ComponentAction:0x00000006566200
  @component=
   {:id=>2147897334,
    :group_id=>2147484269,
    :display_name=>"aws_kms__master_key[default]",
    :component_type=>"aws_kms__master_key",
    :implementation_id=>2147896917,
    :basic_type=>"service",
    :version=>"master",
    :only_one_per_node=>false,
    :external_ref=>
     {:entrypoint=>"bin/create/execute.rb",
      :gems=>["aws-sdk-kms", "aws-sdk-iam", "aws-sdk-ec2"],
      :provider=>"dynamic",
      :type=>"ruby"},
    :node_node_id=>2147897327,
    :extended_base=>nil,
    :ancestor_id=>2147896933,
    :assembly_id=>2147897326,
    :node=>
     {:id=>2147897327,
      :display_name=>"assembly_wide",
      :group_id=>2147484269,
      :external_ref=>
       {:git_authorized=>true, :image_id=>nil, :type=>"ec2_instance"},
      :ordered_component_ids=>nil,
      :type=>"assembly_wide"},
    :title=>"default",
    :action_defs=>
     [{:method_name=>"delete",
       :id=>2147896942,
       :display_name=>"delete",
       :group_id=>2147484269,
       :component_component_id=>2147896933}],
    :source=>
     {:type=>"assembly",
      :object=>{:id=>2147897326, :display_name=>"kms-test"}}},
  @configured_node=
   {:id=>2147897327,
    :display_name=>"assembly_wide",
    :group_id=>2147484269,
    :external_ref=>
     {:git_authorized=>true, :image_id=>nil, :type=>"ec2_instance"},
    :ordered_component_ids=>nil,
    :type=>"assembly_wide"},
  @index=0,
  @on_remote_node=nil>,

This method wil need to be called almist as is. The only issues that needs to eb considered is making sure that it returns the list of relvant actionbs, i.e., ones that appear in teh workflow you are parsing. I dont think it is aproblem if this has info about all component isnatnces in teh service isnatnce (just an efficiency issue you dont have to worry about). Now dsecending into this method you see
[18, 27] in /home/dtk1/server/current/application/model/task/template/action_list/config_components.rb
   18: module DTK; class Task; class Template
   19:   class ActionList
   20:     class ConfigComponents < self
   21:       def self.get(assembly, opts = {})
   22:         # component_list_filter_proc includes clause to make sure no target refs
=> 23:         assembly.get_component_info_for_action_list(seed: new, filter_proc: component_list_filter_proc(opts)).set_action_indexes!
   24:       end
   25:     end

assembly is the assembly instance you are passing in from workflow adapter. The value after filter_proc: is a lambda that can filter to return a subset of actions. To make it simply tag this line with a TODO comment but you can simple do
# assembly.get_component_info_for_action_list(seed: new)
No what .set_action_index! is takes the list actions and adds indexes that are used so you have pointers to the actions in the list. This needs to be called. So in summary you need to call
# assembly.get_component_info_for_action_list(seed: new).set_action_indexes!

One key thing taht is relevant for you is to make sure that the workflow steps are annotated with the right information so it knows whether the component is being executed assembly wide or on a node. I wil let you drill into  assembly.get_component_info_for_action_list to see what its doing. Here is a few summary points. Now stopping at

54, 63] in /home/dtk1/server/current/application/model/assembly/instance/get.rb
   54:     #### end: get methods around attribute mappings
   55:
   56:     #### get methods around components
   57:
   58:     def get_component_info_for_action_list(opts = {})
=> 59:       get_field?(:display_name)
   60:       assembly_source = { type: 'assembly', object: hash_subset(:id, :display_name) }
   61:       component_instances = get_objs_helper(:instance_component_list, :nested_component, opts.merge(augmented: true))
   62:       Component::Instance.add_title_fields?(component_instances)
   63:       Component::Instance.add_action_defs!(component_instances)
   64:       Component::Instance.update_components_on_remote_nodes!(component_instances, self)
   65:       ret = opts[:add_on_to] || opts[:seed] || []
   66:       component_instances.each { |r| ret << r.merge(source: assembly_source) }
   67:       ret


You see steps I wil explain at high level. notced the first line  get_field?(:display_name) does nothing and is in a sense a harmless bug that can be removed
What component_instances = get_objs_helper(:instance_component_list, :nested_component, opts.merge(augmented: true)) is get the component isnatnces that are in teh assembly. Th next imporant code to look at is 
64:       Component::Instance.update_components_on_remote_nodes!(component_instances, self)
You might not have an example that runs on aremote node, but what this does is to see what components are assembly-wide
but the DSL is such that it shoudl really run on a node on another service instance. Ignore details about what node it is setting it to, key is that its patching what is initially returned by get_objs_helper(:instance_component_list, :nested_component, opts.merge(augmented: true))
to change the appropriate node attributes in the component instances so that it points to what the real node is.
Now in our case component instances as specified by the action workflow def might run on a specific node as indicated in this specfication. This si one place where this can be done. However at the end of this new set of comments I suggest two other palces this can be done


Now skipping ahead after the list of component actions is computed we see when teh workflow is parsed with the component action list passed in as a paramter

at /home/dtk1/server/current/application/model/task/template/config_components/persistence.rb
=> 36:         if serialized_content = get_serialized_content_from_assembly(assembly, task_action, task_params: opts[:task_params])
serialized_content looks like
{:subtasks=>
  [{:components=>["ec2::node[test]"], :name=>"create test node"},
   {:components=>["node_utility::ssh_access[ubuntu]"], :name=>"ssh access"},
   {:components=>["aws_kms::master_key[default]"],
    :name=>"discover master key"}]}

At step 37 Content.reify(serialized_content)) looks like:
#<XYZ::Task::Template::Content::RawForm:0x00000002a72540
 @serialized_content=
  {:subtasks=>
    [{:components=>["ec2::node[test]"], :name=>"create test node"},
     {:components=>["node_utility::ssh_access[ubuntu]"], :name=>"ssh access"},
     {:components=>["aws_kms::master_key[default]"],
      :name=>"discover master key"}]}>

The result of executing
=> 41:             Content.parse_and_reify(serialized_content, cmp_actions, opts)

is 
[{2147897327=>
   [[#<XYZ::Task::Template::Action::ComponentAction:0x000000034bb0b0
      @component=
       {:id=>2147897334,
        :group_id=>2147484269,
        :display_name=>"aws_kms__master_key[default]",
        :component_type=>"aws_kms__master_key",
        :implementation_id=>2147896917,
        :basic_type=>"service",
        :version=>"master",
        :only_one_per_node=>false,
        :external_ref=>
         {:entrypoint=>"bin/create/execute.rb",
          :gems=>["aws-sdk-kms", "aws-sdk-iam", "aws-sdk-ec2"],
          :provider=>"dynamic",
          :type=>"ruby"},
        :node_node_id=>2147897327,
        :extended_base=>nil,
        :ancestor_id=>2147896933,
        :assembly_id=>2147897326,
        :node=>
         {:id=>2147897327,
          :display_name=>"assembly_wide",
          :group_id=>2147484269,
          :external_ref=>
           {:git_authorized=>true, :image_id=>nil, :type=>"ec2_instance"},
          :ordered_component_ids=>nil,
          :type=>"assembly_wide"},
        :title=>"default",
        :action_defs=>
         [{:method_name=>"delete",
           :id=>2147896942,
           :display_name=>"delete",
           :group_id=>2147484269,
           :component_component_id=>2147896933}],
        :source=>
         {:type=>"assembly",
          :object=>{:id=>2147897326, :display_name=>"kms-test"}}},
      @configured_node=
       {:id=>2147897327,
        :display_name=>"assembly_wide",
        :group_id=>2147484269,
        :external_ref=>
         {:git_authorized=>true, :image_id=>nil, :type=>"ec2_instance"},
        :ordered_component_ids=>nil,
        :type=>"assembly_wide"},
      @index=0,
      @on_remote_node=nil>]]}]

The paramter comp_actios is teh component action list (i.e., has type 
XYZ::Task::Template::ActionList::ConfigComponents that is described in description above

I show descending into this method to show what its doing and explain its output

If you trap after executing
27, 36] in /home/dtk1/server/current/application/model/task/template/content/serialized_content_array.rb
=> 32:           subtasks             = Constant.matches?(serialized_content, :Subtasks)  || ([] if empty_subtasks?(serialized_content

wil see that subtasks is like the input given it but normalizes it to take into account in DTK workflow there are a number of different syntactic forms that are equivalent; so it maps into a normaized for
subtasts=
[{:components=>["ec2::node[test]"], :name=>"create test node"},
 {:components=>["node_utility::ssh_access[ubuntu]"], :name=>"ssh access"},
 {:components=>["aws_kms::master_key[default]"], :name=>"discover master key"}]

Skipping over the next few steps since they are lower level detail

The next key step is
[40, 49] in /home/dtk1/server/current/application/model/task/template/content/serialized_content_array.rb
=> 45:           Content.new(new(normalized_subtasks), actions, opts.merge(subtask_order: subtask_order, content_params: content_params))
wwhose output is the
[{2147897327=>
   [[#<XYZ::Task::Template::Action::ComponentAction:0x000000034bb0b0
      @component=
       {:id=>2147897334, ..
structure shown above. Now wil descend into this method


Steeping through and descending into
31, 40] in /home/dtk1/server/current/application/model/task/template/content.rb
   31:       def initialize(object = nil, actions = [], opts = {})
   32:         super()
   33:         @subtask_order  = opts[:subtask_order]
   34:         @custom_name    = opts[:custom_name]
   35:         @content_params = opts[:content_params]
=> 36:         create_stages!(object, actions, opts) if object
actions is the component action list

Not stepping into this we reach

[192, 201] in /home/dtk1/server/current/application/model/task/template/content.rb
   192:           self[internode_stage_index - 1]
   193:         end
   194:       end
   195:
   196:       def create_stages!(object, actions, opts = {})
=> 197:         if object.is_a?(TemporalConstraints)
   198:           create_stages_from_temporal_constraints!(object, actions, opts)
   199:         elsif object.is_a?(SerializedContentArray)
   200:           create_stages_from_serialized_content!(object, actions, opts)
In our case we just have to worry about 
 200:           create_stages_from_serialized_content!(object, actions, opts)
So in writing the logic if you are directly calling create_stages!(object, actions, opts)
you can instead call create_stages_from_serialized_content!(object, actions, opts)

Now, stopping next at line 212, which gets called for each step in teh workflow
[207, 216] in /home/dtk1/server/current/application/model/task/template/content.rb
   207:       #  :just_parse (Boolean)
   208:       #  :subtask_order
   209:       #  ...
   210:       def create_stages_from_serialized_content!(serialized_content_array, actions, opts = {})
   211:         serialized_content_array.each do |serialized_content|
=> 212:           if stage = Stage::InterNode.parse_and_reify?(serialized_content, actions, opts)
First time 212 is reached is
(byebug) serialized_content
{:components=>["ec2::node[test]"], :name=>"create test node"}

The next instersting place to stop which is within Stage::InterNode.parse_and_reify? is


94, 103] in /home/dtk1/server/current/application/model/task/template/stage/inter_node/multi_node.rb
    94:               cmp_title = Regexp.last_match(2)
    95:             end
    96:
    97:             matching_actions = action_list.select { |a| a.match_component_ref?(cmp_type, cmp_title) }
    98:             matching_actions.each do |a|
=>  99:               node_id = a.node_id
   100:               pntr = info_per_node[node_id] ||= { actions: [], name: a.node_name, id: node_id, retry: @retry || opts[:retry], attempts: opts[:attempts] }
   101:               pntr[:actions] << serialized_action
   102:             end
   103:           end

This is place where node info is isnerted. We wil need o make sure these is property set as described in a comment above. 

So in summary a key thing that will force a tweak is making sire that the hierarchical task structure has leaf nodes that have the right node set. I mentioned two options
1 - do it when producing the component action list
2 - do it in code right above
3 - a third option that might be lesat coding may be to do it as a post processing operation. Specfically, with respect to below
[231, 240] in /home/dtk1/server/current/application/model/task/create.rb
   231:         fail Error.new("Unexpected component_type (#{component_type})")
   232:       end
   233:
   234:       opts_tt = opts.merge(component_type_filter: component_type)
   235:       task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly, :node_centric], assembly, opts_tt)
=> 236:       stages_config_nodes_task = task_template_content.create_subtask_instances(task_mh, assembly.id_handle())

we could insert a step in between 235 and 236 that modifies task_template_content to change any node refefernce that needs to be changed because of what is in the action workflow def

=end
    end

    def self.create_for_delete_from_database(assembly, component, node, opts = {})
      unless node.is_a?(Node)
        if node.eql?('assembly_wide')
          node = assembly.has_assembly_wide_node?
        else
          leaf_nodes = assembly.get_leaf_nodes()
          node = leaf_nodes.find{|n| n[:display_name].eql?(node)}
        end
      end

      task_name = delete_from_db_task_name(assembly, component, node)
      task_mh   = target_idh_from_assembly(assembly).create_childMH(:task)
      ret       = create_top_level_task(task_mh, assembly, task_action: task_name)

      executable_action = Action::DeleteFromDatabase.create_hash(assembly, component, node, opts)
      return executable_action if opts[:return_executable_action]
      subtask = create_new_task(task_mh, executable_action: executable_action)
      ret.add_subtask(subtask)
      ret
    end

    def self.delete_from_db_task_name(assembly, component, node)
      what =
        if component
          component.get_field?(:display_name)
        elsif node
          node.get_field?(:display_name)
        else
          assembly.get_field?(:display_name)
        end
      # "delete '#{what}' from database"
      "delete from database"
    end

    def self.create_for_command_and_control_action(assembly, action, params, node, opts = {})
      task_mh = target_idh_from_assembly(assembly).create_childMH(:task)
      ret = create_top_level_task(task_mh, assembly, task_action: (opts[:task_action]||'delete_nodes'))
      executable_action = Action::CommandAndControlAction.create_hash(assembly, action, params, node, opts)
      return executable_action if opts[:return_executable_action]
      subtask = create_new_task(task_mh, executable_action: executable_action)
      ret.add_subtask(subtask)
      ret
    end

    #  opts can have keys:
    #   :component_type
    #   :commit_msg, 
    #   :task_action
    #   :start_nodes
    #   :ret_nodes_to_start
    #   TODO: ....
    def self.create_from_assembly_instance?(assembly, opts = {})      
      component_type = opts[:component_type] || :service
      target_idh     = target_idh_from_assembly(assembly)
      task_mh        = target_idh.create_childMH(:task)

      nodes_to_create, nodes_wait_for_start = nodes_to_process_in_task(assembly, Aux.hash_subset(opts, [:start_nodes, :ret_nodes_to_start]))
      case component_type
       when :service
        # start stopped nodes
        unless nodes_wait_for_start.empty?
          node_scs = StateChange::Assembly.node_state_changes(:wait_for_node, assembly, target_idh, just_leaf_nodes: true, nodes: nodes_wait_for_start)
          # TODO: misnomer Action::PowerOnNode; they really just do 'wait until started' 
          start_nodes_task = NodesTask.create_subtask(Action::PowerOnNode, task_mh, node_scs)
        end
        # TODO: DTK-2938; remove
        # create nodes
        # unless nodes_to_create.empty?
        #  node_scs = StateChange::Assembly.node_state_changes(:create_node, assembly, target_idh, just_leaf_nodes: true, nodes: nodes_to_create)
        #  create_nodes_task = NodesTask.create_subtask(Action::CreateNode, task_mh, node_scs)
        # end
        create_nodes_task = nil
       when :smoketest then nil # smoketest should not create a node
       else
        fail Error.new("Unexpected component_type (#{component_type})")
      end

      opts_tt = opts.merge(component_type_filter: component_type)
      # require 'byebug'
      # require 'byebug/core'
      # Byebug.wait_connection = true
      # Byebug.start_server('localhost', 5555)
      # debugger
      task_template_content = Template::ConfigComponents.get_or_generate_template_content([:assembly, :node_centric], assembly, opts_tt)
      #task_template_content now contains our action def
      #In our method create for workflow action: we change those 
      stages_config_nodes_task = task_template_content.create_subtask_instances(task_mh, assembly.id_handle())

      opts.merge!({task_params: opts_tt[:task_params], content_params: task_template_content.content_params})
      ret = create_top_level_task(task_mh, assembly, Aux.hash_subset(opts, [:commit_msg, :task_action, :retry, :attempts, :task_params, :content_params]))

      if start_nodes_task.nil? && create_nodes_task.nil? && stages_config_nodes_task.empty?
        # means that no steps to execute
        return nil
      end

      ### TODO: DTK-2974: lines to end: TODO: DTK-2974 should be removed and we will use another mechanism other than check_for_breakpoint to handle breakpoints
      ids = []
      task_template_content.each do |config_node_action|
        config_node_action.each {|action| ids << action[1][0][0].id }
      end

      parent_field_name = DB.parent_field(:component, :attribute)
      sp_hash = {
          relation: :attribute,
          filter: [:oneof, parent_field_name, ids],
          columns: [:id, :display_name, parent_field_name, :external_ref, :attribute_value, :required, :dynamic, :dynamic_input, :port_type, :port_is_external, :data_type, :semantic_type, :hidden]
      }
      serialized_content = DTK::Task::Template::ConfigComponents::Persistence::AssemblyActions.get_serialized_content_from_assembly(assembly, task_action = nil, task_params: opts[:task_params])
      Log.debug("Adding subtasks: #{serialized_content}")
      ###### end: TODO: DTK-2974
      ret.add_subtask(create_nodes_task) if create_nodes_task
      ret.add_subtask(start_nodes_task) if start_nodes_task
      ret.add_subtasks(stages_config_nodes_task) unless stages_config_nodes_task.empty?
      ret[:retry] = serialized_content[:retry] unless serialized_content[:retry].nil? 
      ret[:attempts] = serialized_content[:attempts] unless serialized_content[:attempts].nil?
      ret
    end



    def self.string_between_markers(string, marker1, marker2) 
        string[/#{Regexp.escape(marker1)}(.*?)#{Regexp.escape(marker2)}/m, 1]
    end

    # returns [nodes_to_create, nodes_wait_for_start]
    #  opts can have keys:
    #   :start_nodes
    #   :ret_nodes_to_start
    def self.nodes_to_process_in_task(assembly, opts = {})
      nodes_to_create = []
      nodes_wait_for_start = []

      node_cols = [:id, :display_name, :type, :external_ref, :admin_op_status, :to_be_deleted]
      assembly_nodes = assembly.get_leaf_nodes(remove_assembly_wide_node: true, cols: node_cols)

      ng_members_to_delete = assembly_nodes.select{ |node| node[:ng_member_deleted] }
      ng_members_to_delete.each{ |node| node.destroy_and_delete(dont_change_cardinality: true) }
      assembly_nodes.reject!{ |node| ng_members_to_delete.include?(node) or  node[:to_be_deleted]}

      assembly_nodes.each do |node|
        external_ref = node.external_ref
        if !external_ref.created?
          nodes_to_create << node
        else
          if opts[:start_nodes]
            nodes_wait_for_start << node
            opts[:ret_nodes_to_start] << node
          elsif external_ref.dns_name?.nil?
            # this is handling case where task got stuck where there it is started but does not have a dns address yet
            # by putting under nodes_wait_for_start there will be a wait intil get its address
            nodes_wait_for_start << node
          end
        end
      end
      [nodes_to_create, nodes_wait_for_start]
    end
    private_class_method :nodes_to_process_in_task
      

    #TODO: below will be private when finish refactoring this file
    def self.target_idh_from_assembly(assembly)
      assembly.get_target().id_handle()
    end
    def self.create_new_task(task_mh, hash)
      Task.create_stub(task_mh, hash)
    end

    def self.create_top_level_task(task_mh, assembly, opts = {})
      task_info_hash = {
        assembly_id: assembly.id,
        display_name: opts[:task_action] || 'assembly_converge',
        temporal_order: opts[:temporal_order] || 'sequential',
        retry: opts[:retry],
        attempts: opts[:attempts],
        task_params: opts[:task_params],
        content_params: opts[:content_params]
      }
      if commit_msg = opts[:commit_msg]
        task_info_hash.merge!(commit_message: commit_msg)
      end

      Log.info("Creating new task named #{task_info_hash[:display_name]}, temporal order: #{task_info_hash[:temporal_order]}")
      create_new_task(task_mh, task_info_hash)
    end
  end

  #TODO: move from below when decide whether needed; looking to generalize above so can subsume below
  module CreateClassMixin
    def task_when_nodes_ready_from_assembly(assembly, component_type, opts)
      assembly_idh = assembly.id_handle()
      target_idh = target_idh_from_assembly(assembly)
      task_mh = target_idh.create_childMH(:task)

      main_task = create_new_task(task_mh, assembly_id: assembly_idh.get_id(), display_name: 'power_on_nodes', temporal_order: 'concurrent', commit_message: nil)
      opts.merge!(main_task: main_task)

      assembly_config_changes = StateChange::Assembly.component_state_changes(assembly, component_type)
      create_running_node_task_from_assembly(task_mh, assembly_config_changes, opts)
    end

    private

    def target_idh_from_assembly(assembly)
      Create.target_idh_from_assembly(assembly)
    end

    def create_nodes_task(task_mh, state_change_list)
      return nil unless state_change_list and not state_change_list.empty?
      # each element will be list with single element
      ret = nil
      all_actions = []
      if state_change_list.size == 1
        executable_action = Action::CreateNode.create_from_state_change(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh, executable_action: executable_action)
      else
        ret = create_new_task(task_mh, display_name: 'create_node_stage', temporal_order: CreateNodeStageTemporalOrder)
        state_change_list.each do |sc|
          executable_action = Action::CreateNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(executable_action: executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::CreateNode.add_attributes!(attr_mh, all_actions)
      ret
    end
    CreateNodeStageTemporalOrder = 'concurrent'

    def create_running_node_task_from_assembly(task_mh, state_change_list, opts = {})
      main_task = opts[:main_task]
      nodes = opts[:nodes]
      nodes_wo_components = []

      # for powering on node with no components
      unless state_change_list and not state_change_list.empty?
        unless node = opts[:node]
          fail Error.new('Expected that :node passed in as options')
        end

        executable_action = Action::PowerOnNode.create_from_node(node)
        attr_mh = task_mh.createMH(:attribute)
        Action::PowerOnNode.add_attributes!(attr_mh, [executable_action])
        ret = create_new_task(task_mh, executable_action: executable_action, display_name: 'power_on_node')
        main_task.add_subtask(ret)

        return main_task
      end

      if nodes
        nodes_wo_components = nodes.dup
        state_change_list.each do |sc|
          if node = sc.first[:node]
            nodes_wo_components.delete_if { |n| n[:id] == node[:id] }
          end
        end
      end

      ret = nil
      all_actions = []
      if nodes_wo_components.empty?
        # if assembly start called from node/node_id context,
        # do not start all nodes but one that command is executed from
        state_change_list = state_change_list.select { |s| s.first[:node][:id] == opts[:node][:id] } if opts[:node]

        # each element will be list with single element
        if state_change_list.size == 1
          executable_action = Action::PowerOnNode.create_from_state_change(state_change_list.first.first)
          all_actions << executable_action
          ret = create_new_task(task_mh, executable_action: executable_action, display_name: 'power_on_node')
          main_task.add_subtask(ret)
        else
          # ret = create_new_task(task_mh,:display_name => "power_on_nodes", :temporal_order => "concurrent")
          state_change_list.each do |sc|
            executable_action = Action::PowerOnNode.create_from_state_change(sc.first)
            all_actions << executable_action
            main_task.add_subtask_from_hash(executable_action: executable_action, display_name: 'power_on_node')
          end
        end
      else
        nodes.each do |node|
          executable_action = Action::PowerOnNode.create_from_node(node)
          all_actions << executable_action
          ret = create_new_task(task_mh, executable_action: executable_action, display_name: 'power_on_node')
          main_task.add_subtask(ret)
        end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::PowerOnNode.add_attributes!(attr_mh, all_actions)
      main_task
    end

    def create_running_node_task(task_mh, state_change_list, opts = {})
      # for powering on node with no components
      unless state_change_list and not state_change_list.empty?
        unless node = opts[:node]
          fail Error.new('Expected that :node passed in as options')
        end
        executable_action = Action::PowerOnNode.create_from_node(node)
        attr_mh = task_mh.createMH(:attribute)
        Action::PowerOnNode.add_attributes!(attr_mh, [executable_action])
        return create_new_task(task_mh, executable_action: executable_action)
      end

      # each element will be list with single element
      ret = nil
      all_actions = []
      if state_change_list.size == 1
        executable_action = Action::PowerOnNode.create_from_state_change(state_change_list.first.first)
        all_actions << executable_action
        ret = create_new_task(task_mh, executable_action: executable_action)
      else
        # TODO: is create_new_task__create_node_stage() right?
        ret = create_new_task(task_mh, display_name: 'create_node_stage', temporal_order: 'concurrent')
        state_change_list.each do |sc|
          executable_action = Action::PowerOnNode.create_from_state_change(sc.first)
          all_actions << executable_action
          ret.add_subtask_from_hash(executable_action: executable_action)
          end
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::PowerOnNode.add_attributes!(attr_mh, all_actions)
      ret
    end

    # TODO: think asseumption is that each elemnt corresponds to changes to same node; if this is case may change input datastructure
    # so node is not repeated for each element corresponding to same node
    def config_nodes_task(task_mh, state_change_list, assembly_idh = nil, stage_index = nil)
      return nil unless state_change_list and not state_change_list.empty?
      ret = nil
      all_actions = []
      if state_change_list.size == 1
        executable_action, error_msg = get_executable_action_from_state_change(state_change_list.first, assembly_idh, stage_index)
        fail ErrorUsage.new(error_msg) unless executable_action
        all_actions << executable_action
        ret = create_new_task(task_mh, display_name: "config_node_stage#{stage_index}", temporal_order: 'concurrent')
        ret.add_subtask_from_hash(executable_action: executable_action)
      else
        ret = create_new_task(task_mh, display_name: "config_node_stage#{stage_index}", temporal_order: 'concurrent')
        all_errors = []
        state_change_list.each do |sc|
          executable_action, error_msg = get_executable_action_from_state_change(sc, assembly_idh, stage_index)
          unless executable_action
            all_errors << error_msg
            next
          end
          all_actions << executable_action
          ret.add_subtask_from_hash(executable_action: executable_action)
        end
        fail ErrorUsage.new("\n" + all_errors.join("\n")) unless all_errors.empty?
      end
      attr_mh = task_mh.createMH(:attribute)
      Action::ConfigNode.add_attributes!(attr_mh, all_actions)
      ret
    end

    # moved call to ConfigNode.create_from_state_change into this method for error handling with clear message to user
    # if TSort throws TSort::Cyclic error, it means intra-node cycle case
    def get_executable_action_from_state_change(state_change, assembly_idh, stage_index)
      executable_action = nil
      error_msg = nil
      begin
        executable_action = Action::ConfigNode.create_from_state_change(state_change, assembly_idh)
        executable_action.set_inter_node_stage!(stage_index)
      rescue TSort::Cyclic => e
        node = state_change.first[:node]
        display_name = node[:display_name]
        id = node[:id]
        cycle_comp_ids = e.message.match(/.*\[(.+)\]/)[1]
        component_names = []
        state_change.each do |cmp|
          component_names << "#{cmp[:component][:display_name]} (ID: #{cmp[:component][:id]})" if cycle_comp_ids.include?(cmp[:component][:id].to_s)
        end
        error_msg = "Intra-node components cycle detected on node '#{display_name}' (ID: #{id}) for components: #{component_names.join(', ')}"
      end
      [executable_action, error_msg]
    end

    def group_by_node_and_type(state_change_list)
      indexed_ret = {}
      state_change_list.each do |sc|
        type =  map_state_change_to_task_action(sc[:type])
        unless type
          Log.error("unexpected state change type encountered #{sc[:type]}; ignoring")
          next
        end
        node_id = sc[:node][:id]
        indexed_ret[type] ||= {}
        indexed_ret[type][node_id] ||= []
        indexed_ret[type][node_id] << sc
      end
      indexed_ret.inject({}) { |ret, o| ret.merge(o[0] => o[1].values) }
    end

    def map_state_change_to_task_action(state_change)
      @mapping_sc_to_task_action ||= {
        'create_node' => Action::CreateNode,
        'install_component' => Action::ConfigNode,
        'update_implementation' => Action::ConfigNode,
        'converge_component' => Action::ConfigNode,
        'setting' => Action::ConfigNode
      }
      @mapping_sc_to_task_action[state_change]
    end

    def create_new_task(task_mh, hash)
      Create.create_new_task(task_mh, hash)
    end
  end
end; end

=begin
Rich: 1/28
Vedad, when you write "We do not have info for node group catapult_node". Here is how you get that info:

When you have a handle on the assembly (instance) you can get all the node and node groups in the assembly as shown below:

[17, 26] in /home/dtk1/server/current/application/model/task/create.rb
   17: #
   18: module DTK; class Task
   19:   module CreateClassMixin
   20:     def create_from_assembly_instance?(assembly, opts = {})
(byebug) pp assembly.get_nodes
[{:id=>2147924882,
  :display_name=>"ng",
  :group_id=>2147484269,
  :type=>"node_group_staged"},
 {:id=>2147924883,
  :display_name=>"assembly_wide",
  :group_id=>2147484269,
  :type=>"assembly_wide"},
 {:id=>2147924881,
  :display_name=>"node1",
  :group_id=>2147484269,
  :type=>"staged"}]

Now here is an new idea how to use this info: in the workflow config_agent when you form the action workflow hash you call
get_nodes on assebly_instance and for each step, knowing what node or node group it is on you can insert an extra key
node_object_id:  ID

So if step should be on nodegroup ng you woudl insert with that step
  node_object_id: 2147924882

Now in code below if the step being processed has the {key node_object_id: ID} you use that rather than a.node_id from the action list

If you pass asembly instance so it gets into 
[92, 101] in /home/dtk1/server/current/application/model/task/template/stage/inter_node/multi_node.rb
    92:             if cmp_ref =~ CmpRefWithTitleRegexp
    93:               cmp_type = Regexp.last_match(1)
    94:               cmp_title = Regexp.last_match(2)
    95:             end
    96:
=>  97:             matching_actions = action_list.select { |a| a.match_component_ref?(cmp_type, cmp_title) }
    98:             matching_actions.each do |a|
    99:               node_id = a.node_id
   100:               pntr = info_per_node[node_id] ||= { actions: [], name: a.node_name, id: node_id, retry: @retry || opts[:retry], attempts: opts[:attempts] }
   101:               pntr[:actions] << serialized_action

Now a little more detail how to do this:

In constructor:

[17, 26] in /home/dtk1/server/current/application/model/task/template/stage/inter_node/multi_node.rb
   17: #
   18: module DTK; class Task; class Template; class Stage
   19:   class InterNode
   20:     class MultiNode < self
   21:       def initialize(serialized_multinode_action)
=> 22:         super(serialized_multinode_action[:name], serialized_multinode_action[:breakpoint], serialized_multinode_action[:retry], serialized_multinode_action[:attempts])
   23:         @ordered_components, @components_or_actions_key = components_or_actions(serialized_multinode_action)
   24:         @breakpoint = serialized_multinode_action[:breakpoint]
   25:         @retry = serialized_multinode_action[:retry]
   26:         @attempts = serialized_multinode_action[:attempts]

We add a new instance attribute @node_object_id it compute its value (which could nil)
@node_object_id = serialized_multinode_action[:node_object_id]

So for example we might reach this rather tan seeing something like
pp serialized_multinode_action
{:components=>["wf::on_node[default]"], :name=>"on_node"}

you optionally might have:

{:components=>["wf::on_node[default]"], :name=>"on_node", :node_object_id=>ID_OF_NODE_THAT_COMPUTED_FROM_WORKFLOW_CONFIG_AGENT}

and therefore get @node_object_id is a non null value and the code can case on this and insert ID_OF_NODE_THAT_COMPUTED_FROM_WORKFLOW_CONFIG_AGENT

=end

