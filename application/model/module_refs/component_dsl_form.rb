module DTK; class ModuleRefs
  class ComponentDSLForm < Hash
    def initialize(component_module,namespace)
      super()
      replace(:component_module => component_module, :remote_namespace => namespace)
    end
    private :initialize

    def component_module()
      self[:component_module]
    end
    def namespace?()
      self[:remote_namespace]
    end
    def namespace()
      unless ret = self[:remote_namespace]
        Log.error("namespace shoudl not be called when self[:remote_namespace] is empty")
      end
      ret
    end

    # returns a hash with keys component_module_name and value MatchedInfo
    # :match_type can be
    #   :dsl - match with element in dsl
    #   :single_match - match with unique component module
    #   :multiple_match - match with more than one component modules
    MatchInfo = Struct.new(:match_type,:match_array) # match_arrat is an array of ComponentDSLForm elements
    def self.get_ndx_module_info(project_idh,module_class,module_branch,opts={})
      ret = Hash.new
      raw_cmp_mod_refs = Parse.get_component_module_refs_dsl_info(module_class,module_branch)
      return raw_cmp_mod_refs if raw_cmp_mod_refs.kind_of?(ErrorUsage::Parsing)
      # put in parse_form
      cmp_mod_refs = raw_cmp_mod_refs.map{|r|new(r[:component_module],r[:remote_namespace])}
      # prune out any that dont have namespace
      cmp_mod_refs.reject!{|cmr|!cmr.namespace?}

      # find component modules (in parse form) that matches a component module found in dsl or
      # in opts; module_names are the relevant modle names to return info about
      module_names = (cmp_mod_refs.map{|r|r.component_module} + opts[:include_module_names]||[]).uniq
      cmp_mods_dsl_form = get_matching_component_modules__dsl_form(project_idh,module_names)

      # for each element in cmp_mod_refs that has a namespace see if it matches an existing component module
      # if not return an error
      dangling_cmp_mod_refs = Array.new
      cmp_mod_refs.each do |cmr|
        unless cmp_mods_dsl_form.find{|cmp_mod|cmp_mod.match?(cmr)}
          dangling_cmp_mod_refs << cmr
        end
      end
      unless dangling_cmp_mod_refs.empty?
        # TODO: is this redundant with 'inconsistent external depenedency?
        cmrs_print_form = dangling_cmp_mod_refs.map{|cmr|cmr.print_form}.join(',')
        err_msg = "The following component module references in the module refs file do not exist: #{cmrs_print_form}"
        return ErrorUsage::Parsing.new(err_msg)
      end

      cmp_mod_refs.each do |cmr|
        ret[cmr.component_module] = MatchInfo.new(:dsl,[cmr])
      end
      if opts[:include_module_names]
        opts[:include_module_names].each do |module_name|
          # only add if not there already
          unless ret[module_name]
            match_array = cmp_mods_dsl_form.select{|cmr|module_name == cmr.component_module()}
            unless match_array.empty?
              match_type = (match_array.size == 1 ? :single_match : :multiple_match)
              ret[module_name] = MatchInfo.new(match_type,match_array)
            end
          end
        end
      end
      ret
    end

    def self.create_from_module_branches?(module_branches)
      ret = nil
      if module_branches.nil? or module_branches.empty?
        return ret 
      end
      mb_idhs = module_branches.map{|mb|mb.id_handle()}
      ModuleBranch.get_namespace_info(mb_idhs).map do |r|
        new(r[:component_module][:display_name],r[:namespace][:display_name])
      end
    end

    def print_form()
      if ns = namespace?() 
        "#{ns}:#{component_module()}"
      else
        component_module()
      end
    end
    
    def match?(cmr)
      namespace?() == cmr.namespace? and component_module() == cmr.component_module()
    end

   private
    def self.get_matching_component_modules__dsl_form(project_idh,module_names)
      opts = {
        :cols => [:namespace_id,:namespace],
        :filter => [:oneof,:display_name,module_names]
      }
      matching_modules = ComponentModule.get_all_with_filter(project_idh,opts)
      matching_modules.map{|m| new(m[:display_name],m[:namespace][:name])} 
    end
  end
end; end

