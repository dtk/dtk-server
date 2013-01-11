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

    def reify!(parent)
      @parent = parent
      cmp_modules = component_modules()
      cmp_modules.each{|mod,constraint|cmp_modules[mod] = Constraint.reify?(constraint)}
      self
    end

    def self.reify_component_modules(cmp_modules)
      cmp_modules
    end

    def save!(parent_idh=nil)
      parent_idh ||= parent_idh()

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

    #TODO: we may simplify relationship of component ref to compoennt template to simplify and make more efficient below
    #augmented with :component_template key which points to associated component template or nil 
    def get_matching_component_template_ids(aug_cmp_refs)
      ret = Hash.new
      return ret if aug_cmp_refs.empty?
      #for each element in aug_cmp_ref, want to set cmp_template_id using following rules
      # 1) if has_override_version is set
      #    a) if it points to a component template, use this
      #    b) otherwise raise error
      # 2) elsif element does not point to a component template need to look it up in module_version_constraints and error if it does not exist
      # 3) else look it up and if lookup exists use this as teh value to use
      cmp_types_to_check = Hash.new
      aug_cmp_refs.each do |r|
        if r[:has_override_version]
          unless self[:component_template_id]
            raise Error.new("Component ref with id (#{r[:id]}) that has override-version flag set needs a component_template id")
          end
        elsif r[:component_template]
          cmp_type = r[:component_template][:component_type]
          (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r}
        elsif r[:component_type]
          cmp_type = r[:component_type]
          (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r, :required => true}
        else
          raise Error.new("component ref with id (#{r[:id]} must either point to a component template or have component_type set")
        end
      end

      #shortcut if no locked versions
      if component_modules().empty?
        if el = cmp_types_to_check.values.find{|r|r.mapping_required?()}
          raise Error.new("Mapping is required for Component ref with id (#{el[:pntr][:id]}), but none exists")
          return aug_cmp_ref
        end
      end
      
      #Lookup up modules mapping
      #mappings will have for each component type that has a module_version_constraints the related component template id
      mappings = get_component_type_to_template_id_mappings?(cmp_types_to_check.keys)

raise Error.new("Got here")
      #TODO: finish
    end


   private

    class ComponentTypeToCheck < Array
      def mapping_required?()
        find{|r|r[:required]}
      end
    end

    def get_component_type_to_template_id_mappings?(cmp_types)
      ret = Hash.new
      return ret if cmp_types.empty?
      type_version_pairs = Array.new
      cmp_types.each do |cmp_type|
        if version = ret_scalar_version?(cmp_type)
          type_version_pairs << {:component_type => cmp_type, :version => version, :version_field => ModuleBranch.version_field(version)}
        end
      end
      return ret if type_version_pairs.empty?

      #get matching component template ids
      matching_templates = Component::Template.get_matching_type_and_version(project_idh,type_version_pairs)
      matching_templates.inject(Hash.new) do |h,r|
        h.merge(r[:component_type] => r[:id])
      end
    end

    def ret_scalar_version?(component_type)
      ret = component_modules[key(Component.module_name(component_type))]
      ret && ret.is_scalar?()
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

    def parent_idh()
      @parent.id_handle()
    end
    def project_idh()
      unless project_id = @parent.get_field?(:project_project_id)
        raise Error.new("Cannot find project from parent object")
      end
      @parent.model_handle(:project).createIDH(:id => project_id)
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

      def is_scalar?()
        @value if @type == :scalar
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
