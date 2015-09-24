module DTK; class AttributeLink
  # TODO: may fold into AttributeLink::Function              
  class PropagateProcessor
    r8_nested_require('propagate_processor', 'legacy')
    include Propagate::Mixin
    include LegacyMixin

    attr_reader :function, :index_map, :attr_link_id, :input_attr, :output_attr, :input_path, :output_path
    def initialize(attr_link, input_attr, output_attr)
      @function = attr_link[:function]
      @index_map = IndexMap.convert_if_needed(attr_link[:index_map])
      @attr_link_id =  attr_link[:id]
      @input_attr = input_attr
      @output_attr = output_attr
      @input_path = attr_link[:input_path]
      @output_path = attr_link[:output_path]
    end

    # propagate from output var to input var
    def propagate
      hash_ret = Function.internal_hash_form?(@function, self)

      unless hash_ret ||= legacy_internal_hash_form?()
        fail Error::NotImplemented.new("propagate value not implemented yet for fn #{@function}")
      end

      hash_ret.is_a?(Output) ? hash_ret : Output.new(hash_ret)
    end

  end
end; end
