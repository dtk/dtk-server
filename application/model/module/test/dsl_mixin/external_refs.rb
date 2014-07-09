module DTK; class TestModule

  class ExternalDependencies < Hash
    def initialize(match_hashes,inconsistent,possibly_missing)
      super()
      replace(:match_hashes => match_hashes, :inconsistent => inconsistent, :possibly_missing => possibly_missing)
    end

    def possible_problems?()
      ret = Aux.hash_subset(self,[:inconsistent,:possibly_missing])
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
          ret = check_and_ret_external_ref_dependencies?(external_ref,project)
        end
        ret
      end

     private
      def set_external_ref?(module_branch,config_agent_type,impl_obj)
        if external_ref = ConfigAgent.parse_external_ref?(config_agent_type,impl_obj)
          # update external_ref column in module.branch table with data parsed from Modulefile
          module_branch.update_external_ref(external_ref[:content]) if external_ref[:content]
          external_ref
        end
      end

      # TODO: move this to under config_agent/puppet
      def parse_dependencies(dependencies)
        dependencies.map do |dep|
          name, version = dep.split(',')
          parsed_dep = {:name=>name}
          if version_constraints = (version && get_dependency_condition(version.strip!()))
            parsed_dep.merge!(:version_constraints=>version_constraints)
          end
          parsed_dep
        end
      end

      # TODO: move this to under config_agent/puppet
      def get_dependency_condition(versions)
        conds, multiple_versions = [], []
        # multiple_versions = versions.split(' ')

        matched_versions = versions.match(/(^[>=<]+\s*\d\.\d\.\d)\s*([>=<]+\s*\d\.\d\.\d)*/)
        multiple_versions << matched_versions[1] if matched_versions[1]
        multiple_versions << matched_versions[2] if matched_versions[2]

        multiple_versions.each do |version|
          match = version.to_s.match(/(^>*=*<*)(.+)/)
        conds << {:version=>match[2], :constraint=>match[1]}
        end

        conds
      end

      # TODO: factor to seperate into puppet specfic parts and general parts
      # move puppet specific to under config_agent/puppet
      def check_and_ret_external_ref_dependencies?(external_ref,project)
        ret = Hash.new
        unless dependencies = external_ref[:dependencies]
          return ret
        end
        parsed_dependencies, all_match_hashes, all_inconsistent, all_possibly_missing = [], {}, [], []
        # using begin rescue statement to avoid import failure if parsing errors or if using old Modulefile format
        begin
          parsed_dependencies = parse_dependencies(dependencies)
         rescue Exception => e
          Log.error_pp([e,e.backtrace[0..20]])
        end
        all_modules = TestModule.get_all(project.id_handle())
        parsed_dependencies.each do |parsed_dependency|
          dep_name = parsed_dependency[:name].strip()
          version_constraints = parsed_dependency[:version_constraints]
          match, inconsistent, possibly_missing = nil, nil, nil

          # if there is no component_modules or just this one in database, mark all dependencies as possibly missing
          all_modules_except_this = all_modules.reject{|r|r[:id] == id()}
          all_possibly_missing << dep_name if all_modules_except_this.empty?

          all_modules_except_this.each do |cmp_module|
            branches = cmp_module.get_module_branches()

            branches.each do |branch|
              unless branch[:external_ref].nil?
                # TODO: get rid of use of eval
                branch_hash = eval(branch[:external_ref])
                branch_name = branch_hash[:name].gsub('-','/').strip()
                branch_version = branch_hash[:version]

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

                        evaluated = eval("#{br_version}#{constraint_op}#{req_version}")
                        break if evaluated == false
                      end
                    end

                    if evaluated
                      all_match_hashes.merge!(dep_name  => branch)
                    else
                      all_inconsistent << "#{dep_name} (current:#{branch_version}, required:#{constraint_op}#{required_version})"
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
        all_inconsistent = (all_inconsistent - all_match_hashes.keys)
        all_possibly_missing = (all_possibly_missing - all_inconsistent - all_match_hashes.keys)
        ExternalDependencies.new(all_match_hashes,all_inconsistent.uniq,all_possibly_missing.uniq)
      end

    end # ExternalRefsMixi
  end #ManagementMixin
end; end
