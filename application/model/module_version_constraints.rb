module DTK
  class ModuleVersionConstraints < Model
    def self.create_and_reify?(module_branch_parent,module_version_constraints=nil)
      module_version_constraints ||= ModuleVersionConstraints.create_stub(module_branch_parent.model_handle(:module_version_constraints))
      module_version_constraints.reify!(module_branch_parent)
    end

    #TODO: we may simplify relationship of component ref to compoennt template to simplify and make more efficient below
    #augmented with :component_template key which points to associated component template or nil 
    def set_matching_component_template_info!(aug_cmp_refs,opts={})
      ret = aug_cmp_refs
      return ret if aug_cmp_refs.empty?
      #for each element in aug_cmp_ref, want to set cmp_template_id using following rules
      # 1) if has_override_version is set
      #    a) if it points to a component template, use this
      #    b) otherwise look it up using given version
      # 2) else look it up and if lookup exists use this as teh value to use; element marked required if it does not point to a component template
      cmp_types_to_check = Hash.new
      aug_cmp_refs.each do |r|
        unless cmp_type = r[:component_type]||(r[:component_template]||{})[:component_type]
          ref =  ErrorDanglingComponentRefs.pp_component_ref(r)
          ref = (ref ? "(#{ref})" : "")
          raise Error.new("Component ref #{ref} must either point to a component template or have component_type set")
        end
        if r[:has_override_version]
          unless r[:component_template_id]
            unless r[:version]
              raise Error.new("Component ref has override-version flag set, but no version")
            end
            (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r, :version => r[:version]}
          end
        else
          (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r,:required => r[:component_template_id].nil?}
        end
      end

      #shortcut if no locked versions and no required elements
      if component_modules().empty? and not cmp_types_to_check.values.find{|r|r.mapping_required?()}
        return ret
      end
      
      #Lookup up modules mapping
      #mappings will have for each component type that has a module_version_constraints the related component template id
      mappings = get_component_type_to_template_mappings?(cmp_types_to_check.keys)

      #set the compoennt template ids; raise error if there is a required element that does not have a matching component template
      error_cmp_refs = Array.new
      cmp_types_to_check.each do |cmp_type,els|
        els.each do |el|
          if cmp_template = mappings[cmp_type]
            el[:pntr][:component_template_id] = cmp_template[:id] 
            if opts[:donot_set_component_template]
              el[:pntr][:component_template] = cmp_template
            end
          elsif el[:required]
            error_cmp_refs << el[:pntr]
          end
        end
      end
      raise ErrorMissingComponentTemplates.new(error_cmp_refs) unless error_cmp_refs.empty?
      ret
    end
                                                                          
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

    def save!(parent_idh=nil)
      parent_idh ||= parent_idh()

      #update model
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

      #update git repo
      ServiceModule::GlobalModuleRefs.serialize_and_save_to_repo(@parent)

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

    class ErrorDanglingComponentRefs < ErrorUsage
      def initialize(cmp_refs)
        super(err_msg(cmp_refs))
      end
      def self.pp_component_ref(component_ref)
        if component_ref[:component_type]
          Component.pp_component_type(component_ref[:component_type])
        elsif component_ref[:id]
          "id:#{component_ref[:id].to_s})"
        end
      end
     private
      def err_msg(cmp_refs)
        what = (cmp_refs.size==1 ? "component ref" : "component refs")
        refs = cmp_refs.map{|cmp_ref|self.class.pp_component_ref(cmp_ref)}.compact.join(",")
        verb = (cmp_refs.size==1 ? "does" : "do")
        "The referenced #{what} (#{refs}) #{verb} not exist"
      end
    end

   private
    class ComponentTypeToCheck < Array
      def mapping_required?()
        find{|r|r[:required]}
      end
    end

    def get_component_type_to_template_mappings?(cmp_types)
      ret = Hash.new
      return ret if cmp_types.empty?
      type_version_pairs = Array.new
      cmp_types.each do |cmp_type|
        version = ret_selected_version(cmp_type)
        type_version_pairs << {:component_type => cmp_type, :version => version, :version_field => ModuleBranch.version_field(version)}
      end
      return ret if type_version_pairs.empty?

      #get matching component template ids
      matching_templates = Component::Template.get_matching_type_and_version(project_idh(),type_version_pairs)
      matching_templates.inject(Hash.new) do |h,r|
        h.merge(r[:component_type] => r)
      end
    end

    def ret_selected_version(component_type)
      ret = component_modules[key(Component.module_name(component_type))]
      if ret.nil? then ret 
      elsif ret.is_scalar?() then ret.is_scalar?()
      else
        raise Eeror.new("Not treating the version type")
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

    def parent_idh()
      @parent.id_handle()
    end
    def project_idh()
      return @project_idh if @project_idh
      unless service_id = @parent.get_field?(:service_id)
        raise Error.new("Cannot find project from parent object")
      end
      service_module = @parent.model_handle(:service_module).createIDH(:id => service_id).create_object()
      unless project_id = service_module.get_field?(:project_project_id)
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
