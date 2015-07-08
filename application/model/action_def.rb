module DTK
  class ActionDef < Model
    r8_nested_require('action_def','content')
    def self.common_columns
      core_columns()+[:method_name,:content,:component_component_id]
    end

    module Constant
      module Variations
      end
      extend Aux::ParsingingHelper::ClassMixin
      CreateActionName = 'create'
    end

    def self.get_ndx_action_defs(cmp_template_idhs,opts={})
      ret = {}
      return ret if cmp_template_idhs.empty?

      sp_hash = {
        cols: opts[:cols] ? (opts[:cols]+core_columns()+[:component_component_id]).uniq : common_columns(),
        filter: [:oneof,:component_component_id,cmp_template_idhs.map{|cmp|cmp.get_id{}}]
      }
      action_def_mh = cmp_template_idhs.first.createMH(:action_def)
      get_objs(action_def_mh,sp_hash).each do |ad|
        (ret[ad[:component_component_id]] ||= []) << ad
      end
      ret
    end
    ColsToInclude = [:id,:group_id,:component_component_id]

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

    def parse_and_reify_content?
      content = get_field?(:content)
      unless content.is_a?(Content)
        if content.is_a?(Hash)
          hash_content = content
          self[:content] = Content.parse(hash_content)
        else
          raise Error.new("Unexpected class type (#{content.class}")
        end
      end
      self[:content]
    end
  end
end
