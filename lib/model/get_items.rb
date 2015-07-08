# TODO: should this be put under model directory and pssiblty folded into specfic classes
module XYZ
  module GetItemsInstanceMixins
    def get_items
      objects =  sub_item_model_names.inject([]) do |r,m|
        r + get_objects_col_from_sp_hash({columns: ["#{m}s".to_sym]},m)
      end
      objects.each{|o|o[:model_name] = o.model_name}
      add_ui_positions_if_needed!(objects)
    end

    private

    def add_ui_positions_if_needed!(objects)
      default_pos = DefaultPositions.new(model_name)
      objects.each do |o|
        o[:ui] ||= {}
        pos = o[:ui][id().to_s.to_sym] ||= {}
        pos[:left] ||= default_pos.ret_and_increment(o.model_name,:left)
        pos[:top] ||= default_pos.ret_and_increment(o.model_name,:top)
      end
    end

    class DefaultPositions
      def initialize(ws_model_name)
        # TODO: simplifying assumption that these are constant accross all workspaces; ws_model_name param is hook for handling this
        @ws_model_name = ws_model_name
        @positions = deep_copy(StartPositions)
      end

      def ret_and_increment(model_name,axis)
        ret = @positions[model_name][axis]
        @positions[model_name][axis] += Increment[model_name][axis]
        ret
      end

      private

      Increment = {
        component: {left: 50, top: 50},
        node: {left: 50, top: 50},
        node_group: {left: 50, top: 50}
      }
      StartPositions = {
        component: {left: 200, top: 100},
        node: {left: 200, top: 100},
        node_group: {left: 100, top: 100}
      }
      def deep_copy(pos_hash)
        pos_hash.inject({}) do |oh,okv|
          oh.merge(okv[0] => okv[1].inject({}){|ih,ikv|ih.merge(ikv[0] => ikv[1])})
        end
      end
    end
  end
end
