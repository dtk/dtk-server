module DTK; class Task; class Template
  class TemporalConstraint
    class ConfigComponent < self
      class IntraNode
        def intra_node?()
          true
        end
      end

      class PortLinkOrder < self
        def inter_node?()
          true
        end
      end

      class DynamicAttribute
        def inter_node?()
          true
        end
      end

    end
  end
end; end; end
