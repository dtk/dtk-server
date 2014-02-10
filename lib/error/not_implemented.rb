module DTK
  class Error
    class NotImplemented < self
      def initialize(msg="NotImplemented error")
        super("in #{this_parent_parent_method}: #{msg}",:NotImplemented)
      end
    end
  end
end


