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
  class Create
    class WorkflowAction
      module ClassMixin
        def create_for_workflow_action(assembly, task_info, component_workflow)
          WorkflowAction.new(assembly, task_info, component_workflow).create_for_workflow_action
        end
      end
      
      def initialize(assembly, task_info, component_workflow)
        @assembly           = assembly
        @task_info          = task_info
        @component_workflow = component_workflow
        @task_params        = task_info[:task_params]
        @content_params     = task_info[:content_params]
        @task_id            = task_info[:top_task_id]
      end
      
      def create_for_workflow_action
        # require 'byebug'
        # require 'byebug/core'
        # Byebug.wait_connection = true
        # Byebug.start_server('localhost', 5555)
        # debugger
        ret = self.top_level_task
        # Rich 1/31: not sure what 'ret[:task_id] = @task_id' is suppose to impact.
        ret[:task_id] = @task_id

        task_template_content = Template::Content.parse_and_reify(self.serialized_content, self.component_actions, self.parse_and_reify_opts)
        subtasks = task_template_content.create_subtask_instances(self.task_mh, self.assembly.id_handle)
        ret.add_subtasks(subtasks)
        ret
      end
      
      protected
      
      attr_reader :assembly, :task_info, :component_workflow
      
      def top_level_task
        fail(Error, "Unexpected that content and task parameters are not hashes") unless param_is_hash?

        # Rich 1/31: Need a way to mark this as a subtask so that when cancel a task we dont get subtasks
        # I wrote Task.qualified_subtask_name to do that
        opts = {
          task_action: Task.qualified_subtask_name(self.task_info[:top_task_display_name]),
          retry: self.task_info[:retry],
          task_params: @task_params,
          attempts: self.task_info[:attempts],
          content_params: @content_params
        }
        Create.create_top_level_task(self.task_mh, self.assembly, opts) 
      end
      
      def param_is_hash?
        (@task_params.is_a?(Hash) || @task_params.nil?) && (@content_params.is_a?(Hash) || @content_params.nil?)
      end
      
      def component_actions
        @component_actions ||= Template::ActionList::ConfigComponents.get(self.assembly)
      end
      
      def serialized_content
        @serialized_content ||= Template.serialized_content_hash_form(subtasks: self.component_workflow.subtasks_content)
      end
      
      def parse_and_reify_opts
        { component_type_filter: :service, 
          task_action: self.task_info[:top_task_display_name], 
          breakpoint: self.task_info[:breakpoint], 
          nodes: self.assembly.get_nodes 
        }      
      end

      def task_mh
        @task_mh ||= self.assembly.get_target.id_handle.create_childMH(:task)
      end
      
    end
  end
end; end

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

