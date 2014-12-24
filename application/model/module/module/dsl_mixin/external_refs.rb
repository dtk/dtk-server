module DTK; class BaseModule
              
  class ExternalDependencies < Hash
    def initialize(hash={})
      super()
      replace(hash)
    end

    def possible_problems?()
      ret = Aux.hash_subset(self,[:inconsistent,:possibly_missing,:ambiguous])
      ret unless ret.empty? 
    end

    def matching_module_branches?()
      if match_hashes = self[:match_hashes]
        ndx_ret = match_hashes.values.inject(Hash.new) do |h,r|
          h.merge(r.id() => r)
        end
        ndx_ret.values unless ndx_ret.empty?
      end
    end
  end              

  module DSLMixin
    module ExternalRefsMixin
      def process_external_refs(module_branch,config_agent_type,project,impl_obj)
        ret = nil
        if external_ref = set_external_ref?(module_branch,config_agent_type,impl_obj)
          ret = check_and_ret_external_ref_dependencies?(external_ref,project,module_branch)
        end
        ret
      end

      def set_external_ref?(module_branch,config_agent_type,impl_obj)
        if external_ref = ConfigAgent.parse_external_ref?(config_agent_type,impl_obj) 
          # update external_ref column in module.branch table with data parsed from Modulefile
          module_branch.update_external_ref(external_ref[:content]) if external_ref[:content]
          external_ref
        end
      end

     private
      # TODO: move matching logic under DTK::ConfigAgent::Adapter::Puppet::ExternalDependency::ParsedForm
      # move puppet specific to under config_agent/puppet
      def check_and_ret_external_ref_dependencies?(external_ref,project,module_branch=nil)
        ret = ExternalDependencies.new()
        return ret unless dependencies = external_ref[:dependencies]

        parsed_dependencies = dependencies.map{|dep|dep.parsed_form?()}.compact
        return ret if parsed_dependencies.empty?

        all_match_hashes, all_inconsistent, all_possibly_missing, all_inconsistent_names = {}, [], [], []
        all_ambiguous, all_ambiguous_ns = [], []
        all_modules = self.class.get_all(project.id_handle()).map{|cmp_mod|ComponentModuleWrapper.new(cmp_mod)}
        existing_module_refs = get_existing_module_refs(module_branch)
        parsed_dependencies.each do |parsed_dependency|
          dep_name = parsed_dependency[:name].strip()
          version_constraints = parsed_dependency[:version_constraints]
          match, inconsistent, possibly_missing = nil, nil, nil
          
          # if there is no component_modules or just this one in database, mark all dependencies as possibly missing
          all_modules_except_this = all_modules.reject{|cmp_mod_wrapper|cmp_mod_wrapper.id == id()}
          all_possibly_missing << dep_name if all_modules_except_this.empty?
          
          all_modules_except_this.each do |cmp_mod_w|
            cmp_mod_w.module_branches().each do |branch_w|
              if branch_w.has_external_ref?()
                branch = branch_w.branch
                branch_name = branch_w.branch_name
                branch_version = branch_w.branch_version
                
                if (branch_name && branch_version)
                  matched_branch_version = branch_version.match(/(\d+\.\d+\.\d+)/)
                  branch_version = matched_branch_version[1]

                  evaluated, br_version, constraint_op, req_version, required_version = false, nil, nil, nil, nil
                  if dep_name.eql?(branch_name)
                    # version_constraints.nil? means no version consttaint
                    if version_constraints.nil?
                      evaluated = true
                    else
                      version_constraints.each do |vconst|
                        required_version = vconst[:version]
                        br_version       = branch_version.gsub('.','')
                        constraint_op    = vconst[:constraint]
                        req_version      = required_version.gsub('.','')
                        
                        # if version contraints in form of 4.x
                        if req_version.to_s.include?('x')
                          req_version.gsub!(/x/,'')
                          evaluated = br_version.to_s.start_with?(req_version.to_s)
                        else
                          evaluated = eval("#{br_version}#{constraint_op}#{req_version}")
                        end
                        break if evaluated == false
                      end
                    end

                    if evaluated
                      if all_match_hashes.has_key?(dep_name)
                        if all_ambiguous.empty?
                          namespace_info = all_match_hashes[dep_name].get_namespace_info
                          all_ambiguous << {:name => dep_name, :namespace => namespace_info[:namespace][:display_name]}
                        end
                        namespace_info = branch.get_namespace_info
                        all_ambiguous << {:name => dep_name, :namespace => namespace_info[:namespace][:display_name]}
                      end

                      if existing_module_refs.empty?
                        all_match_hashes.merge!(dep_name  => branch)
                      else
                        name = dep_name.split('/').last
                        namespace_info = branch.get_namespace_info
                        existing_namespace = existing_module_refs['component_modules']["#{name}"]
                        if existing_namespace && existing_namespace['namespace'].eql?(namespace_info[:namespace][:display_name])
                          all_match_hashes.merge!(dep_name  => branch)
                        end
                      end
                    else
                      all_inconsistent << "#{dep_name} (current:#{branch_version}, required:#{constraint_op}#{required_version})"
                      all_inconsistent_names << dep_name
                    end

                  else
                    all_possibly_missing << dep_name
                  end   
                end
              else
                all_possibly_missing << dep_name
              end
            end
          end
        end

        check_if_matching_or_ambiguous(module_branch, all_ambiguous)
        all_ambiguous_ns = all_ambiguous.map{|am| am[:name]} unless all_ambiguous.empty?
        unless all_ambiguous_ns.empty? || all_match_hashes.empty?
          all_ambiguous_ns.uniq!
          all_match_hashes.delete_if{|k,v|all_ambiguous_ns.include?(k)}
        end

        ambiguous_grouped = {}
        unless all_ambiguous.empty?
          ambiguous_g = all_ambiguous.group_by { |h| h[:name] }
          ambiguous_g.each do |k,v|
            namespaces = v.map{|a| a[:namespace]}
            ambiguous_grouped.merge!(k => namespaces)
          end
        end

        all_inconsistent = (all_inconsistent - all_match_hashes.keys)
        all_possibly_missing = (all_possibly_missing.uniq - all_inconsistent_names - all_match_hashes.keys - all_ambiguous_ns.uniq)
        ext_deps_hash = {
          :match_hashes => all_match_hashes,
          :inconsistent => all_inconsistent.uniq,
          :possibly_missing => all_possibly_missing.uniq
        }
        ext_deps_hash.merge!(:ambiguous => ambiguous_grouped) unless ambiguous_grouped.empty?
        ExternalDependencies.new(ext_deps_hash)
      end

      def check_if_matching_or_ambiguous(module_branch, ambiguous)
        existing_c_hash = get_existing_module_refs(module_branch)
        if existing = existing_c_hash['component_modules']
          existing.each do |k,v|
            amb = ambiguous.select{|a| a[:name].split('/').last.eql?(k) && a[:namespace].eql?(v['namespace'])}
            ambiguous.delete_if{|amb| amb[:name].split('/').last.eql?(k)} unless amb.empty?
          end
        end
      end

      def get_existing_module_refs(module_branch)
        existing_c_hash  = {}
        existing_content = RepoManager.get_file_content({:path => "module_refs.yaml"}, module_branch, {:no_error_if_not_found => true})
        existing_c_hash  = Aux.convert_to_hash(existing_content,:yaml) if existing_content
        existing_c_hash
      end
      # for caching info
      class ComponentModuleWrapper
        def initialize(cmp_mod)
          @cmp_mod = cmp_mod
        end
        def id()
          @cmp_mod.id()
        end
        def module_branches()
          @module_branches ||= @cmp_mod.get_module_branches().map{|b|Branch.new(b)}
        end

        class Branch
          attr_reader :branch
          def initialize(branch)
            @branch = branch
          end
          def has_external_ref?()
            !external_ref.nil?
          end
          def branch_name()
            (branch_hash[:name]||'').gsub('-','/').strip()
          end
          def branch_version
            branch_hash[:version]
          end
         private
          def external_ref()
            @branch[:external_ref]
          end
          def branch_hash()
            # TODO: get rid of use of eval; for metadata source dont turn into string in first place
            @branch_hash ||= (external_ref && eval(external_ref))||{}
          end
        end
      end

    end # ExternalRefsMixi
  end #ManagementMixin
end; end
