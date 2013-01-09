module DTK
  class ModuleVersionConstraints < Model
    def include_module_version?(cmp_module_name,version)
      module_constraint(cmp_module_name).include?(version)
    end

    def include_module?(cmp_module_name)
      component_modules.has_key?(key(cmp_module_name))
    end

    private
     def module_constraint(cmp_module_name)
       Constraint.reify?(component_modules[key(cmp_module_name)])
     end

     def component_modules()
       ((self[:constraints]||{})[:component_modules])||{}
     end

     def key(el)
       el.to_sym
     end

     class Constraint
       def self.reify?(constraint=nil)
         if constraint.nil? then new()
         elsif constraint.kind_of?(Constraint) then constraint
         elsif constraint.kind_of?(string) then new(constraint)
         else
           raise Error.new("Constraint of form (#{constraint.inspect}) not treated")
         end
       end

       def include?(version)
         case @type
           when :empty
           nil
         when :scalar
           @value == version
         end
       end

      private
       def initialize(scalar=nil)
         @type = (scalar ? :scalar : :empty)
         @value = scalar
       end

       def empty?()
         @type == :empty?
       end
     end
  end
end
