# TODO: simplify by changing target arg to be just idh
module XYZ
  class Constraints < Array
    def initialize(logical_op = :and, constraints = [])
      super(constraints)
      @logical_op = logical_op
    end

    def evaluate_given_target(target, opts = {})
      ret = evaluate_given_target_just_eval(target, opts)
      return ret if ret

      target_parent_obj = target.values.first.get_parent_id_handle().create_object
      violations = ret_violations(target)
      if opts[:raise_error_when_any_violation]
        all_violations = Violation::Expression(violations['error'], violations['warning'])
        fail ErrorConstraintViolations.new(all_violations.pp_form)
      elsif opts[:raise_error_when_error_violation]
        pp [:warnings, violations['warning'].pp_form]
        Violation.save(target_parent_obj, violations['warning'])
        fail ErrorConstraintViolations.new(violations['error'].pp_form) unless violations['error'].empty?
      else
        pp [:errors, violations['error'].pp_form]
        Violation.save(target_parent_obj, violations['error'])
        pp [:warnings, violations['warning'].pp_form]
        Violation.save(target_parent_obj, violations['warning'])
      end
      ret
    end

    private

    def evaluate_given_target_just_eval(target, opts = {})
      return true if self.empty?
      self.each do |constraint|
        constraint_holds = constraint.evaluate_given_target(target, opts)
        case @logical_op
          when :or
            return true if constraint_holds
          when :and
            return false unless constraint_holds
        end
      end
      case @logical_op
        when :or then false
        when :and then true
      end
    end

    public

    def ret_violations(target)
      ret = { 'error' => Violation::Expression.new(target, @logical_op), 'warning' => Violation::Expression.new(target, @logical_op) }

      self.each do |constraint|
        next if constraint.evaluate_given_target(target)
        severity = constraint[:severity] || 'error'
        ret[severity] << constraint
      end
      ret
    end

    module Macro
      private

      class Common
        def self.component_i18n
          @@component_i18n ||= Model.get_i18n_mappings_for_models(:component)
        end
        def self.string_symbol_form(term)
          if term.is_a?(Symbol)
            ":#{term}"
          elsif term.is_a?(String)
            term
          elsif term.is_a?(Hash)
            term.inject({}) { |h, kv| h.merge(string_symbol_form(kv[0]) => string_symbol_form(kv[1])) }
          elsif term.is_a?(Array)
            term.map { |t| string_symbol_form(t) }
          else
            Log.error("unexpected form for term #{term.inspect}")
          end
        end
      end

      public

      class RequiredComponent < Common
        def self.search_pattern(required_component)
          hash = {
           filter: [:eq, :component_type, required_component]
          }
         string_symbol_form(hash)
        end
        def self.description(required_component, base_component)
          "#{print_form(required_component)} is required for #{print_form(base_component)}"
        end

        private

        def self.print_form(cmp_display_name)
          i18n = Model.i18n_string(component_i18n, :component, cmp_display_name)
          i18n || cmp_display_name.split(name_delimiter()).map(&:capitalize).join(' ')
        end
      end
    end
  end

  class Constraint < HashObject
    def self.create(dependency)
      if dependency[:type] == 'attribute' && dependency[:attribute_attribute_id]
        PortConstraint.new(dependency)
      elsif dependency[:type] == 'component' && dependency[:component_component_id]
        ComponentConstraint.new(dependency)
      else
        fail Error.new('unexpected dependency type')
      end
    end
    def evaluate_given_target(target, opts = {})
      # if no :search_pattern then this is a 'necessary fail'
      return false unless search_pattern
      dataset = create_dataset(target)
      rows = dataset.all

      # opportunistic gathering of info
      update_object_from_info_gathered!(opts[:update_object], rows) if opts[:update_object]

      is_empty = rows.empty?
      self[:negate] ? is_empty : (not is_empty)
    end

    module Macro
      def self.only_one_per_node(component_type)
        user_friendly_type = Component.display_name_print_form(component_type)
        dep = {
          description: "Only one component of type #{user_friendly_type} can be on a node",
          severity: 'error',
          negate: true,
          search_pattern: {
            filter: [:eq, :component_type, component_type]
          }
        }
        ComponentConstraint.new(dep)
      end
      def self.base_for_extension(extension_cmp_info)
        ext_name = extension_cmp_info[:component_type]
        dep = {
          description: "Base component for extension#{ext_name ? " (#{ext_name})" : ''} not on node",
          severity: 'error',
          search_pattern: {
            filter: [:eq, :component_type, extension_cmp_info[:extended_base]]
          }
        }
        ComponentConstraint.new(dep)
      end

      def self.no_legal_endpoints(external_link_defs)
        eps = external_link_defs.remote_components
        # no search pattern means 'necessarily fail'
        dep = {
          description: "Link must attach to node with a component of type (#{eps.join(', ')})",
          severity: 'error'
        }
        PortConstraint.new(dep)
      end
    end

    private

    def initialize(dependency)
      super
      reformat_search_pattern!()
    end

    def reformat_search_pattern!
      self[:search_pattern] = search_pattern && SearchPattern.create_just_filter(search_pattern)
      self
    end

    def search_pattern
      self[:search_pattern]
    end

    # overrwritten
    def update_object_from_info_gathered!(_object, _rows)
      fail Error.new("not treating constraint update of object of type #{obj.class}")
    end
  end

  module ProcessVirtualComponentMixin
    # converts from form that acts as if attributes are directly attached to component
    def ret_join_array(join_cond)
      real = []
      virtual = []
      real_cols = real_component_columns()
      search_pattern.break_filter_into_conjunctions().each do |conjunction|
        parsed_comparision = SearchPatternSimple.ret_parsed_comparison(conjunction)
        if real_cols.include?(parsed_comparision[:col])
          real << conjunction
        else
          virtual << parsed_comparision
        end
      end

      cols = [:id, :display_name]
      cols << join_cond.keys.first unless cols.include?(join_cond.keys.first)
      direct_component = {
        model_name: :component,
        join_type: :inner,
        join_cond: join_cond,
        cols: cols
      }
      direct_component.merge!(filter: [:and] + real) unless real.empty?

      if virtual.empty?
        [direct_component]
      else
        [direct_component] +
          virtual.map do |v|
          {
            model_name: :attribute,
            alias: v[:col],
            filter: [v[:op], v[:col], v[:constant]],
            join_type: :inner,
            join_cond: { component_component_id: :component__id },
            cols: [:id, :display_name]
          }
        end
      end
    end

    def real_component_columns
      @@real_component_columns ||= DB_REL_DEF[:component][:columns].keys
    end
  end

  class ComponentConstraint < Constraint
    private

    include ProcessVirtualComponentMixin
    def create_dataset(target)
      node_idh  =
        if target['target_node_id_handle']
          target['target_node_id_handle']
        elsif target['target_component_id_handle']
          target['target_component_id_handle'].get_containing_node_id()
        else
          fail Error.new('unexpected target')
        end
      join_cond = { node_node_id: :node__id }
      join_array = ret_join_array(join_cond)
      model_handle = node_idh.createMH(:node)
      base_sp_hash = {
        model_name: :node,
        filter: [:and, [:eq, :id, node_idh.get_id()]],
        cols: [:id]
      }
      base_sp = SearchPatternSimple.new(base_sp_hash)
      SQL::DataSetSearchPattern.create_dataset_from_join_array(model_handle, base_sp, join_array)
    end

    def update_object_from_info_gathered!(object, rows)
      row = rows.first
      return unless self[:info_gathered] && row && row[:component]
      self[:info_gathered].each { |obj_key, k| object[obj_key] = row[:component][k] }
    end
  end

  class PortConstraint < Constraint
    private

    include ProcessVirtualComponentMixin
    def create_dataset(target)
      other_end_idh  = target[:target_port_id_handle]
      join_cond = { id: :attribute__component_component_id }
      join_array = ret_join_array(join_cond)
      model_handle = other_end_idh.createMH(:attribute)
      base_sp_hash = {
        model_name: :attribute,
        filter: [:and, [:eq, :id, other_end_idh.get_id()]],
        cols: [:id, :component_component_id]
      }
      base_sp = SearchPatternSimple.new(base_sp_hash)
      SQL::DataSetSearchPattern.create_dataset_from_join_array(model_handle, base_sp, join_array)
    end
  end
end
