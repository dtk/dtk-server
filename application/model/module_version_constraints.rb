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
      #TODO: here may search through 'linked' component instances and change version associated with them
    end

    def save!(parent_idh=nil)
      parent_idh ||= @parent_idh

      if id() 
        #persisted already, needs update
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
      self
    end

    def set_and_save_constraints!(constraints_hash_form)
      set_constraints(constraints_hash_form)
      save!()
    end

    def constraints_in_hash_form()
      ret = Hash.new
      unless constraints = self[:constraints]
        return ret
      end
      self.class.hash_form(constraints)
    end

    attr_accessor :parent_idh

    #augmented with node and component template info

    def get_augmented_matching_componente_refs(mh,node_stub_ids)

    end

    #TODO: we may simplify relationship of compoennt ref to compoennt template tos implify and make moer efficient below
    def get_matching_component_template_ids(aug_cmp_refs)
      ret = Hash.new
      #for each element in aug_cmp_ref, want to set cmp_template_id using following rules
      # 1) if has_override_version is set
      #    a) if it points to a component template, use this
      #    b) otherwise raise error
      # 2) elsif element does not point to a component template need to look it up in module_version_constraints and error if it does not exist
      # 3) else look it up and if lookup exists use this as teh value to use
      cmp_types_to_check = Hash.new
      aug_cmp_refs.each do |r|
        if r[:has_override_version]
          unless self[:component_template]
            raise Error.new("Component ref with id (#{r[:id]}) that has override-version flag set needs a component_template id")
          end
          r[:component_template_id] = r[:component_template][:id]
        elsif r[:component_template]
          cmp_type = r[:component_template][:component_type]
          (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r}
          #opportunistically setting component_template_id (it, however, might be overwritten)
          r[:component_template_id] = r[:component_template][:id]
        elsif r[:component_type]
          cmp_type = r[:component_type]
          (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r, :required => true}
        else
          raise Error.new("component ref with id (#{r[:id]} must eitehr point to a component template or have component_type set")
        end
      end

      #shortcut if no locked versions
      if component_modules().empty?
        if el = cmp_types_to_check.find{|r|r.mapping_required?()}
          raise Error.new("Mapping is required for Component ref with id (#{el[:pntr][:id]}), but none exists")
          return aug_cmp_ref
        end
      end
      
      #TODO: lookup up modules mapping
      component_modules = ComponentTypeToCheck.ret_modules_to_lookup(cmp_types_to_check)
      #TODO: finish
    end


   private

    class ComponentTypeToCheck < Array
      def mapping_required?()
        find{|r|r[:required]}
      end
    end


    def module_constraint(cmp_module_name)
      Constraint.reify?(component_modules[key(cmp_module_name)])
    end
    
    def component_modules()
      ((self[:constraints]||{})[:component_modules])||{}
    end

    def set_constraints(hash)
      self[:constraints] = hash
    end

    def create_component_modules_hash?()
      (self[:constraints] ||= Hash.new)[:component_modules] ||= Hash.new
    end
    
    def key(el)
      el.to_sym
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
