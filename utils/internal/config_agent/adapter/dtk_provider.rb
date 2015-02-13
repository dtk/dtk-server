module DTK; class ConfigAgent; module Adapter
  class DtkProvider < ConfigAgent
    def ret_msg_content(config_node,opts={})
      # TODO: right now noy using assembly attributes; if use, need way to distingusih between refernce to these and
      # reference to component attributes
      # assembly_attrs = assembly_attributes(config_node)

      commands = commands(config_node)
      # TODO: For Aldin: when action agent changes to signature that takes a list of commands then take this; 
      # since it only takes now single bash command; stubbing by taking first one

      pp [:commands,commands]
      bash_command = commands.first || 'ls /usr'
      ret = {
        :bash_command => bash_command
      }
      if assembly = opts[:assembly]
        ret.merge!(:service_id => assembly.id(), :service_name => assembly.get_field?(:display_name))
      end
      ret
    end

    def type()
      Type::Symbol.dtk_provider
    end

    def interpret_error(error_in_result,components)
      #TODO: stub
      pp [error_in_result,components]
      ret = error_in_result
      ret
    end

    private
    def commands(config_node)
      ret = Array.new
      config_node[:component_actions].each do |component_action|
        each_command_given_component_action(component_action) do |command|
          ret << command
        end
      end
      ret
    end

    def each_command_given_component_action(component_action,&block)
      if action_def = component_action.action_def()
        each_command_given_action_def(action_def,component_action,&block)
      end
    end

    def each_command_given_action_def(action_def,component_action,&block)
      content = action_def.reify_content!()
      (content[:commands]||[]).each do |raw_command|
        #TODO: For Aldin; right now just getting raw commands, but will put objects in ActionDef::Content
        # that distinguish between whether command is a syscallto execute or a file position
        # if syscall here you wil have to case on whether there are mustach attributes in the command
        # or not; if template vraibales then call to attribute_value_pairs(component_action)
        # will give attribute values to substitute
        
        # TODO: stub
        command = raw_command.gsub(/^RUN\s+/,'')
        block.call(command)
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
