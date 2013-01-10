module DTK
  class ModuleVersionConstraints < Model
    def include_module_version?(cmp_module_name,version)
      module_constraint(cmp_module_name).include?(version)
    end

    def include_module?(cmp_module_name)
      component_modules.has_key?(key(cmp_module_name))
    end

    def set_module_version(cmp_module_name,version)
      create_component_modules_hash?()[key(cmp_module_name)] = Constraint.reify?(version)
    end

    def save!(parent_idh)
      #TODO: write to git repo
      if id()
        #persisted already
        update(:constraints => constraints_in_hash_form())
      else
        mh = parent_idh.create_childMH(:module_version_constraints) 
        row = {
          mh.parent_id_field_name() => parent_idh.get_id(),
          :ref => "constraint", #max one per parent so this can be constant
          :constraints => constraints_in_hash_form(),
        }
        @id_handle = Model.create_from_row(mh,row,:convert => true)
      end
    end

    private
     def module_constraint(cmp_module_name)
       Constraint.reify?(component_modules[key(cmp_module_name)])
     end

     def component_modules()
       ((self[:constraints]||{})[:component_modules])||{}
     end

     def create_component_modules_hash?()
       (self[:constraints] ||= Hash.new)[:component_modules] ||= Hash.new
     end

     def key(el)
       el.to_sym
     end

     def constraints_in_hash_form()
       ret = Hash.new
       unless constraints = self[:constraints]
         return ret
       end
       self.class.hash_form(constraints)
     end

     def self.hash_form(el)
       if el.kind_of?(Hash)
         el.inject(Hash.new) do |h,(k,v)|
           if val = hash_form(v)
             h.merge(k => val)
           else
             h
           end
         end
       elsif el.kind_of?(Constraint)
         el.to_s
       else
         el
       end
     end

     class Constraint
       def self.reify?(constraint=nil)
         if constraint.nil? then new()
         elsif constraint.kind_of?(Constraint) then constraint
         elsif constraint.kind_of?(String) then new(constraint)
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

       def to_s()
         case @type
          when :scalar
           @value.to_s
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
