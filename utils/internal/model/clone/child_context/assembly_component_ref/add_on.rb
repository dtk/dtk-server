#for processing AssemblyComponentRefs when assembly being added is an add-on
module DTK;class ChildContext
  class AssemblyComponentRef
    class AddOn < self
    end
  end
end; end
