module DTK
  class ModuleLocation
    class Client < self
      class Local < ModuleLocation::Local
      end
      class Remote < ModuleLocation::Remote
      end
    end
  end
end
