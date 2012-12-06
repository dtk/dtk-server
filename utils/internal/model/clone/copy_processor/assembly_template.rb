module DTK
  class Clone
    class CopyProcessor
      class AssemblyTemplate < self
        def clone_direction()
          :target_to_library
        end
      end
    end
  end
end
