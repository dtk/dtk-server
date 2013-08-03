module DTK; class Task; class Template
  class TemporalConstraint
    class ConfigComponent < self
      class IntraNode < self
        def intra_node?()
          true
        end
      end

      class PortLinkOrder < self
        def inter_node?()
          true
        end
      end

      class DynamicAttribute < self
        def inter_node?()
          true
        end
      end

    end
  end
end; end; end
