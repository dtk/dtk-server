module DTK
  class Node
    class Template < self
      def self.list(model_handle)
        ret = Array.new
        cols = NodeBindingRuleset.common_columns()
        sp_hash = {
          :cols => [:id,:ref,:display_name,:rules,:os_type]
        }
        node_bindings = get_objs(model_handle.createMH(:node_binding_ruleset),sp_hash,:keep_ref_cols => true)
        node_bindings.each do |n|
          n[:rules].each do |r|
            el = {
              :display_name => n[:display_name]||n[:ref], #TODO: may just use display_name after fil in this column
              :os_type => n[:os_type],
            }.merge(r[:node_template])
            ret << el
          end
        end
        ret
      end
    end
  end
end
