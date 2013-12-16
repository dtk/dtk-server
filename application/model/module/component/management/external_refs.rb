module DTK; class ComponentModule
  module ManagementMixin
    module ExternalRefsMixin
      def process_external_refs(module_branch,project,impl_obj)
        ret = Hash.new
        if external_ref = set_external_ref?(module_branch,impl_obj)
          ret = check_and_ret_external_ref_dependencies?(external_ref,project)
        end
        ret
      end

     private
      def set_external_ref?(impl_obj,module_branch)
       # if module contains Modulefile, parse information and store them to module_branch external_ref
        if ComponentDSL.contains_modulefile?(impl_obj)
          external_ref = ComponentDSL.get_modulefile_raw_content_and_info(impl_obj)

          # update external_ref columng in module.branch table with data parsed from Modulefile
          module_branch.update_external_ref(external_ref[:content]) if external_ref[:content]
          external_ref
        end
      end
 
      def check_and_ret_external_ref_dependencies?(external_ref,project)
        ret = Hash
        unless dependencies = external_ref[:dependencies]
          return ret
        end
        parsed_dependencies, all_matched, all_inconsistent, all_possibly_missing = [], [], [], []
          # using begin rescue statement to avoid import failure if parsing errors or if using old Modulefile format
        begin
          parsed_dependencies = ComponentModule.parse_dependencies(dependencies)
         rescue Exception => e
          Log.error_pp([e,e.backtrace(0..20)])
        end
        all_modules = ComponentModule.get_all(project)
        parsed_dependencies.each do |parsed_dependency|
          dep_name = parsed_dependency[:name].strip()
          version_constraints = parsed_dependency[:version_constraints]
          match, inconsistent, possibly_missing = nil, nil, nil
          
          # if there is no component_modules in database, mark all dependencies as possibly missing
          all_possibly_missing << dep_name if all_modules.empty?
          
          all_modules.each do |cmp_module|
            branches = cmp_module.get_module_branches()
            next if cmp_module[:id].eql?(is())
                    
            branches.each do |branch|
              unless branch[:external_ref].nil?
                branch_hash = eval(branch[:external_ref])
                branch_name = branch_hash[:name].gsub('-','/').strip()
                branch_version = branch_hash[:version]
                
                if (branch_name && branch_version)
                  matched_branch_version = branch_version.match(/(\d+\.\d+\.\d+)/)
                  branch_version = matched_branch_version[1]
                  
                  evaluated, br_version, constraint_op, req_version, required_version = false, nil, nil, nil, nil
                  if dep_name.eql?(branch_name)
                    #version_constraints.nil? means no version consttaint
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
                      all_matched << dep_name 
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
        all_inconsistent = (all_inconsistent - all_matched)
        all_possibly_missing = (all_possibly_missing - all_inconsistent - all_matched)
        
        {:match => all_matched.uniq, :inconsistent => all_inconsistent.uniq, :possibly_missing => all_possibly_missing.uniq}
      end

    end # ExternalRefsMixi
  end #ManagementMixin
end; end
