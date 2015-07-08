module DTK; class Assembly; class Instance
  class Update
    def initialize(assembly_idh)
      @assembly_idh = assembly_idh
    end

    def assembly_instance
      @assembly_idh.create_object()
    end

    class Node < self
      class Add < self
      end
      class Delete < self
      end
    end

    class Component < self
      class Add < self
      end
      class Delete < self
      end
    end
  end                               
end; end; end
