module DTK
  class ComponentModuleRefs < Model 
    def self.meta_filename_path()
      "global_module_refs.json"
    end

    def self.create_and_reify?(module_branch_parent,component_module_refs=nil)
      component_module_refs ||= create_stub(module_branch_parent.model_handle(:component_module_refs))
      component_module_refs.reify!(module_branch_parent)
    end

    #TODO: we may simplify relationship of component ref to compoennt template to simplify and make more efficient below
    #augmented with :component_template key which points to associated component template or nil 
    def set_matching_component_template_info!(aug_cmp_refs,opts={})
      ret = aug_cmp_refs
      return ret if aug_cmp_refs.empty?
      #for each element in aug_cmp_ref, want to set cmp_template_id using following rules
      # 1) if key 'has_override_version' is set
      #    a) if it points to a component template, use this
      #    b) otherwise look it up using given version
      # 2) else look it up and if lookup exists use this as the value to use; element marked required if it does not point to a component template
      cmp_types_to_check = Hash.new
      aug_cmp_refs.each do |r|
        unless cmp_type = r[:component_type]||(r[:component_template]||{})[:component_type]
          ref =  ComponentRef.print_form(r)
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
          if r[:template_id_synched] and not opts[:force_compute_template_id]
            raise Error.new("Unexpected that r[:component_template_id] is null for (#{r.inspect})") if r[:component_template_id].nil?
          else
            (cmp_types_to_check[cmp_type] ||= ComponentTypeToCheck.new) << {:pntr => r,:required => r[:component_template_id].nil?}
          end
        end
        r[:template_id_synched] = true #marking each item synchronized
      end

      #shortcut if no locked versions and no required elements
      if component_modules().empty? and not cmp_types_to_check.values.find{|r|r.mapping_required?()}
        return ret
      end

      #Lookup up modules mapping
      #mappings will have key for each component type referenced and for each key will return hash with keys :component_template and :version;
      #component_template will be null if no match is found
      mappings = get_component_type_to_template_mappings?(cmp_types_to_check.keys)

      #set the component template ids; raise error if there is a required element that does not have a matching component template
      reference_errors = Array.new
      cmp_types_to_check.each do |cmp_type,els|
        els.each do |el|
          cmp_type_version_info = mappings[cmp_type]
          if cmp_template = cmp_type_version_info[:component_template]
            el[:pntr][:component_template_id] = cmp_template[:id] 
            unless opts[:donot_set_component_template]
              el[:pntr][:component_template] = cmp_template
            end
          elsif el[:required]
            cmp_ref = {
              :component_type => cmp_type, 
              :version => cmp_type_version_info[:version]
            }
            remote_namespace = nil #TODO: stub to find remote namespace associated with module
            cmp_ref.merge!(:remote_namespace => remote_namespace) if remote_namespace
            reference_errors << cmp_ref
          end
        end
      end
      raise ErrorUsage::DanglingComponentRefs.new(reference_errors) unless reference_errors.empty?
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
      save!()
      #TODO: here may search through 'linked' component instances and change version associated with them
    end

    def reify!(parent)
      @parent = parent
      cmp_modules = component_modules()
      cmp_modules.each{|mod,constraint|cmp_modules[mod] = Constraint.reify?(constraint)}
      self
    end

    def save!(parent_idh=nil,opts={})
      parent_idh ||= parent_idh()

      #update model
      if id() 
        #persisted already, needs update
        update_row = {
          :id => id(),
          :constraints => constraints_in_hash_form()
        }
        #using Model.update_from_row rather than Model#update, because later updates object with set values which serve to overrite the reified constraint hash
        Model.update_from_rows(model_handle(),[update_row])
      else
        mh = parent_idh.create_childMH(:component_module_refs) 
        row = {
          mh.parent_id_field_name() => parent_idh.get_id(),
          :ref => "constraint", #max one per parent so this can be constant
          :constraints => constraints_in_hash_form(),
        }
        @id_handle = Model.create_from_row(mh,row,:convert => true)
      end

      #update git repo
      unless opts[:donot_make_repo_changes]
        meta_filename_path = self.class.meta_filename_path()
        @parent.serialize_and_save_to_repo(meta_filename_path,get_hash_content(@parent))
      end

      self
    end

    def set_and_save_constraints!(constraints_hash_form,opts={})
      reify_and_set_constraints(constraints_hash_form)
      save!(nil,opts)
    end

    def constraints_in_hash_form()
      ret = Hash.new
      unless constraints = self[:constraints]
        return ret
      end
      self.class.hash_form(constraints)
    end

   private
    def get_hash_content(service_module_branch)
      ret = SimpleOrderedHash.new()
      component_module_refs = service_module_branch.get_component_module_refs()
      unordered_hash = component_module_refs.constraints_in_hash_form()
      if unordered_hash.empty?
        return ret
      end
      unless unordered_hash.size == 1 and unordered_hash.keys.first == :component_modules
        raise Error.new("Unexpected key(s) in component_module_refs (#{unordered_hash.keys.join(',')})")
      end
      
      cmp_mods = unordered_hash[:component_modules]
        cmp_mod_contraints = cmp_mods.keys.map{|x|x.to_s}.sort().inject(SimpleOrderedHash.new()){|h,k|h.merge(k => cmp_mods[k.to_sym])}
      ret.merge(:component_modules => cmp_mod_contraints)
    end

    class ComponentTypeToCheck < Array
      def mapping_required?()
        find{|r|r[:required]}
      end
    end

    def get_needed_component_type_version_pairs(cmp_types)
      cmp_types.map do |cmp_type|
        version = ret_selected_version(cmp_type)
        {:component_type => cmp_type, :version => version, :version_field => ModuleBranch.version_field(version)}
      end
    end

    def get_component_type_to_template_mappings?(cmp_types)
      ret = Hash.new
      return ret if cmp_types.empty?
      #first put in ret info about component type and version
      ret = cmp_types.inject(Hash.new) do |h,cmp_type|
        version = ret_selected_version(cmp_type)
        h.merge(cmp_type => {:component_type => cmp_type, :version => version, :version_field => ModuleBranch.version_field(version)})
      end

      #get matching component template info and insert matches into ret
      Component::Template.get_matching_type_and_version(project_idh(),ret.values).each do |cmp_template|
        ret[cmp_template[:component_type]].merge!(:component_template => cmp_template) 
      end
      ret
    end

    def ret_selected_version(component_type)
      ret = component_modules[key(Component.module_name(component_type))]
      if ret.nil? then ret 
      elsif ret.is_scalar?() then ret.is_scalar?()
      elsif ret.empty? then nil
      else
        raise Error.new("Not treating the version type (#{ret.inspect})")
      end
    end

    def module_constraint(cmp_module_name)
      Constraint.reify?(component_modules[key(cmp_module_name)])
    end
    
    def component_modules()
      ((self[:constraints]||{})[:component_modules])||{}
    end

    def reify_and_set_constraints(hash)
      self[:constraints] = 
        if hash.empty? then hash
        elsif hash.size == 1 and hash.keys.first.to_sym == :component_modules
          reify_component_module_contraints(hash.values.first)
        elsif
          raise Error.new("Do not treat module verions contraints of form (#{hash.inspect})")
        end
    end

    def reify_component_module_contraints(hash)
      {:component_modules => hash.keys.inject(Hash.new){|h,k|h.merge(key(k) => Constraint.reify?(hash[k]))}}
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
        elsif constraint.kind_of?(Hash) and constraint.size == 1 and constraint.keys.first == "namespace"
          #MOD_RESTRUCT: TODO: need to decide if depracting 'namespace' key
          Log.info("Ignoring constraint of form (#{constraint.inspect})")
          new()
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

      def empty?()
        @type == :empty
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
      
    end
  end
end
