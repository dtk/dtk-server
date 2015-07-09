module DTK; class Task; class Template
  class Action
    r8_nested_require('action', 'component_action')
    r8_nested_require('action', 'action_method')
    r8_nested_require('action', 'with_method')
    r8_nested_require('action', 'ad_hoc')

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
    # :index
    # :parent_action

    def self.create(object, opts = {})
      if object.is_a?(Component)
        add_action_method?(ComponentAction.new(object, opts), opts)
      elsif object.is_a?(Action)
        add_action_method?(object, opts)
      else
        raise Error.new("Not yet implemented treatment of action of type {#{object.class})")
      end
    end

    def self.find_action_in_list?(serialized_item, node_name, action_list, opts = {})
      # method_name could be nil
      ret = nil

      component_ext_ref_type = nil
      component_name_ref, method_name = WithMethod.parse(serialized_item)

      # if component has external_ref[:type] = 'bash_command' it means it has bash command instead of puppet in create action
      # here we set bash create action to be executed instead of puppet_apply
      method_name ||= set_bash_create_action(action_list, component_name_ref)

      unless action = action_list.find_matching_action(node_name, component_name_ref: component_name_ref)
        if opts[:skip_if_not_found]
          return ret
        else
          raise ParsingError.new("The component reference '#{component_name_ref}' on node '#{node_name}' in the workflow is not in the assembly; either add it to the assembly or delete it from the workflow")
        end
      end

      if cgn = opts[:component_group_num]
        action = action.in_component_group(cgn)
      end

      return create(action) unless method_name

      action_defs = action[:action_defs] || []
      if action_def = action_defs.find { |ad| ad.get_field?(:method_name) == method_name }
        return create(action, action_def: action_def)
      end

      unless opts[:skip_if_not_found]
        err_msg = "The action method '#{method_name}' is not defined on component '#{component_name_ref}'"
        if action_defs.empty?
          err_msg << '; there are no actions defiend on this component.'
        else
          legal_methods = action_defs.map { |ad| ad[:method_name] }
          err_msg << "; legal method names are: #{legal_methods.join(',')}"
        end
        raise ParsingError.new(err_msg)
      end
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
    # this can be overwritten
    def action_method?
      nil
    end

    private

    def self.add_action_method?(base_action, opts = {})
      opts[:action_def] ? base_action.class::WithMethod.new(base_action, opts[:action_def]) : base_action
    end

    def self.set_bash_create_action(action_list, component_name_ref)
      cmp = action_list.find { |a_item| a_item.component_display_name.eql?(component_name_ref.gsub('::', '__')) }
      if cmp && (ext_ref = cmp.external_ref)
        (ext_ref[:type] || '').eql?('bash_command') ? 'create' : nil
      end
    end
  end
end; end; end
