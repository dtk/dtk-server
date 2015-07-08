module DTK; class ModuleRefs
  class ComponentDSLForm < Hash
    # Elements of ComponentDSLForm
    class Elements < Array
      def initialize(*args)
        args = [args] if args.size == 1 && !args.first.is_a?(Array)
        super(*args)
      end

      def add!(a)
        a.each{|el|self << el}
        self
      end
    end

    def initialize(component_module, namespace, external_ref = nil)
      super()
      replace(component_module: component_module, remote_namespace: namespace, external_ref: external_ref)
    end
    private :initialize

    def component_module
      self[:component_module]
    end

    def namespace?
      self[:remote_namespace]
    end

    def namespace
      unless ret = self[:remote_namespace]
        Log.error("namespace should not be called when self[:remote_namespace] is empty")
      end
      ret
    end

    # returns a hash with keys component_module_name and value MatchedInfo
    # :match_type can be
    #   :dsl - match with element in dsl
    #   :single_match - match with unique component module
    #   :multiple_match - match with more than one component modules
    MatchInfo = Struct.new(:match_type,:match_array) # match_array is an array of ComponentDSLForm elements
    def self.get_ndx_module_info(project_idh,module_class,module_branch,opts={})
      ret = {}
      raw_cmp_mod_refs = Parse.get_component_module_refs_dsl_info(module_class,module_branch)
      return raw_cmp_mod_refs if raw_cmp_mod_refs.is_a?(ErrorUsage::Parsing)
      # put in parse_form
      cmp_mod_refs = raw_cmp_mod_refs.map{|r|new(r[:component_module],r[:remote_namespace], r[:external_ref])}

      # prune out any that dont have namespace
      cmp_mod_refs.reject!{|cmr|!cmr.namespace?}

      # find component modules (in parse form) that matches a component module found in dsl or
      # in opts; module_names are the relevant modle names to return info about
      module_names = (cmp_mod_refs.map(&:component_module) + (opts[:include_module_names]||[])).uniq
      return ret if module_names.empty?
      cmp_mods_dsl_form = get_matching_component_modules__dsl_form(project_idh,module_names)

      # for each element in cmp_mod_refs that has a namespace see if it matches an existing component module
      # if not return an error
      dangling_cmp_mod_refs = []
      cmp_mod_refs.each do |cmr|
        unless cmp_mods_dsl_form.find{|cmp_mod|cmp_mod.match?(cmr)}
          dangling_cmp_mod_refs << cmr
        end
      end
      unless dangling_cmp_mod_refs.empty?
        # TODO: is this redundant with 'inconsistent external depenedency?
        cmrs_print_form = dangling_cmp_mod_refs.map(&:print_form).join(',')
        err_msg = "The following component module references in the module refs file do not exist: #{cmrs_print_form}"
        return ErrorUsage::Parsing.new(err_msg)
      end

      cmp_mod_refs.each do |cmr|
        ret[cmr.component_module] = MatchInfo.new(:dsl,ComponentDSLForm::Elements.new(cmr))
      end
      if opts[:include_module_names]
        opts[:include_module_names].each do |module_name|
          # only add if not there already
          unless ret[module_name]
            match_array = ComponentDSLForm::Elements.new(cmp_mods_dsl_form.select{|cmr|module_name == cmr.component_module()})
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
      if module_branches.nil? || module_branches.empty?
        return ret
      end
      mb_idhs = module_branches.map(&:id_handle)
      ret = ComponentDSLForm::Elements.new
      ModuleBranch.get_namespace_info(mb_idhs).each do |r|
        ret << new(r[:component_module][:display_name],r[:namespace][:display_name])
      end
      ret
    end

    def print_form
      if ns = namespace?()
        "#{ns}:#{component_module()}"
      else
        component_module()
      end
    end

    def match?(cmr)
      namespace() == cmr.namespace() && component_module() == cmr.component_module()
    end

    private

    def self.get_matching_component_modules__dsl_form(project_idh,module_names)
      opts = {
        cols: [:namespace_id,:namespace],
        filter: [:oneof,:display_name,module_names]
      }
      matching_modules = ComponentModule.get_all_with_filter(project_idh,opts)
      matching_modules.map{|m| new(m[:display_name],m[:namespace][:name])}
    end
  end
end; end
