module DTK
  class ActionDef < Model
    r8_nested_require('action_def', 'content')
    def self.common_columns
      core_columns() + [:method_name, :content, :component_component_id]
    end

    module Constant
      module Variations
      end
      extend Aux::ParsingingHelper::ClassMixin
      CreateActionName = 'create'
    end
    
    def self.get_action_def(id_handle, opts = {})
      sp_hash = {
        cols:   cols_from_opts(opts),
        filter: [:eq, :id, id_handle.get_id]
      }
      ret = aggregate_parameters?(get_objs(id_handle.createMH, sp_hash), opts)
      if ret.size == 1
        ret.first
      else
        Log.error("Unexpected that size (#{ret.size.to_s}) != 1")
        nil
      end
    end

    def self.get_ndx_action_defs(cmp_template_idhs, opts = {})
      ret = {}
      return ret if cmp_template_idhs.empty?

      sp_hash = {
        cols:   cols_from_opts(opts),
        filter: [:oneof, :component_component_id, cmp_template_idhs.map { |cmp| cmp.get_id {} }]
      }
      action_def_mh = cmp_template_idhs.first.createMH(:action_def)
      rows = get_objs(action_def_mh, sp_hash)
      aggregate_parameters?(rows, opts).each do |ad|
        (ret[ad[:component_component_id]] ||= []) << ad
      end
      ret
    end


    def commands
      parse_and_reify_content?().commands()
    end

    def functions
      parse_and_reify_content?().functions()
    end

    # if parse does not go through; raises parse error
    def self.parse(hash_content)
      Content.parse(hash_content)
    end

    private

    def self.cols_from_opts(opts = {})
      cols = (opts[:cols] ? (opts[:cols] + core_columns() + [:component_component_id]).uniq : common_columns())
      opts[:with_parameters] ? cols + [:parameters] : cols
    end

    def self.aggregate_parameters?(rows, opts = {})
      ret = rows
      return ret unless opts[:with_parameters]

      ndx_by_action_def = {}
      rows.each do |r|
        action_def_id = r[:id]
        parameter = r.delete(:parameter)
        pntr = ndx_by_action_def[action_def_id] ||= r.merge(parameters: [])
        if parameter
          pntr[:parameters] << parameter
        end
      end
      ndx_by_action_def.values
    end

    def parse_and_reify_content?
      content = get_field?(:content)
      unless content.is_a?(Content)
        if content.is_a?(Hash)
          hash_content = content
          self[:content] = Content.parse(hash_content)
        else
          fail Error.new("Unexpected class type (#{content.class}")
        end
      end
      self[:content]
    end
  end
end
