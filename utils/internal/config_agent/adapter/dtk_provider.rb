module DTK; class ConfigAgent; module Adapter
  class DtkProvider < ConfigAgent
    r8_nested_require('dtk_provider','interpret_results')
    include InterpretResults::Mixin

    def ret_msg_content(config_node,opts={})
      # TODO: right now noy using assembly attributes; if use, need way to distingusih between refernce to these and
      # reference to component attributes
      # assembly_attrs = assembly_attributes(config_node)

      commands = commands(config_node, :substitute_template_vars => true)
      ret = {
        :action_agent_request => {
          :execution_list => commands,
        }
      }
      if assembly = opts[:assembly]
        ret.merge!(:service_id => assembly.id(), :service_name => assembly.get_field?(:display_name))
      end
      ret
    end

    def type()
      Type::Symbol.dtk_provider
    end

    
    private
    def commands(config_node,opts)
      ret = Array.new
      config_node[:component_actions].each do |component_action|
        attr_val_pairs = nil
        each_command_given_component_action(component_action) do |command|
          if opts[:substitute_template_vars] and command.needs_template_substitution?()
            attr_val_pairs ||= attribute_value_pairs(component_action)
            command.bind_template_attributes!(attr_val_pairs)
          end

          # if stdout_and_stderr = true we return combined stdout and stderr in action results
          # default value is true unless set otherwise in dsl
          stdout_and_stderr = true
          action_def = component_action.action_def()

          if content = action_def[:content]
            stdout_and_stderr = content[:stdout_and_stderr] unless content[:stdout_and_stderr].nil?
          end

          ret << {
            :type => command.type,
            :command => command.command_line(),
            :stdout_redirect => stdout_and_stderr
          }
        end
      end
      ret
    end

    def each_command_given_component_action(component_action,&block)
      if action_def = component_action.action_def()
        action_def.commands().each do |command|
          block.call(command)
        end
      end
    end

    def attribute_value_pairs(component_action)
      (component_action[:attributes]||[]).inject(Hash.new) do |h,attr|
        h.merge(attr[:display_name] => attr[:attribute_value])
      end
    end

  end
end; end; end
=begin
example action_def
{:id=>2147838183,
  :method_name=>"simple",
  :content=>{:commands=>["RUN ls /usr"], :provider=>"dtk_provider"}}

example node_config
 :component_actions=>
  [{:attributes=>
     [{:id=>2147838077,
       :display_name=>"dir",
       :component_component_id=>2147838076,
       :external_ref=>{:type=>"puppet_attribute", :path=>"node[cmp][dir]"},
       :required=>false,
       :dynamic=>false,
       :data_type=>"string",
       :semantic_type=>nil,
       :hidden=>false,
       :value_asserted=>"/usr",
       :value_derived=>nil,
       :is_port=>false,
       :port_type_asserted=>nil,
       :semantic_type_summary=>nil,
       :is_external=>nil}],
    :component=>
     {:id=>2147838076,
      :group_id=>2147836977,
      :display_name=>"cmp",
      :component_type=>"cmp",
      :implementation_id=>2147838094,
      :basic_type=>"service",
      :version=>"assembly--dsl-test-test1",
      :only_one_per_node=>true,
      :external_ref=>{:type=>"puppet_class", :class_name=>"cmp"},
      :node_node_id=>2147838072,
      :extended_base=>nil,
      :ancestor_id=>2147838100},
    :action_method=>{:method_name=>"simple", :action_def_id=>2147838183}}],
=end
