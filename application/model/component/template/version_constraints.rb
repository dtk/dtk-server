module DTK
  class ComponentVersionConstraints < Model
    def meets_constraint?(cmp_template)
      true
    end
    private
     def constraints()
       self[:constraints]||get_and_reify_constraints()
     end
     def get_and_reify_constraints()
       unless self[:id]
         raise Error.new("ComponentVersionConstraints#get_constraints() shoudl not be called if this is not associated with persisted object")
       end
       reify(update_object!(:constraints))
     end
     def reify(constraints)
       #TODO: stub
       constraints
     end
  end
end
