module DTK
  module ModuleClassMixin
    class ListMethodHelpers
      def self.aggregate_detail(branch_module_rows,module_mh,opts)
        diff       = opts[:diff]
        remote_repo_base = opts[:remote_repo_base]

        if opts[:include_remotes]
          augment_with_remotes_info!(branch_module_rows,module_mh)
        end
        # if there is an external_ref source, use that otherwise look for remote dtkn
        #there can be duplictes for a module when multiple repos; in which case will agree on all fields
        #except :repo, :module_branch, and :repo_remotes
        #index by module
        ndx_ret = Hash.new
        #aggregate
        branch_module_rows.each do |r|
          module_branch = r[:module_branch]
          ndx_repo_remotes = r[:ndx_repo_remotes]
          ndx = r[:id]
          is_equal = nil
          
          if diff
            if default_remote_repo = RepoRemote.ret_default_remote_repo((ndx_repo_remotes||{}).values)
              is_equal = r[:repo].ret_local_remote_diff(module_branch,default_remote_repo)
            end
          end
                    
          unless mdl = ndx_ret[ndx]
            r.delete(:repo)
            r.delete(:module_branch)
            mdl = ndx_ret[ndx] = r
          end
          mdl.merge!(:is_equal => is_equal)

          if opts[:include_versions]
            (mdl[:version_array] ||= Array.new) << module_branch.version_print_form(Opts.new(:default_version_string => DefaultVersionString))
          end
          if external_ref_source = module_branch.external_ref_source()
            mdl[:external_ref_source] = external_ref_source
          end
          if ndx_repo_remotes
            ndx_repo_remotes.each do |remote_repo_id,remote_repo|
              (mdl[:ndx_repo_remotes] ||= Hash.new)[remote_repo_id] ||= remote_repo
            end
          end
        end
        #put in display name form
        ndx_ret.each_value do |mdl|
          if raw_va = mdl.delete(:version_array)
            unless raw_va.size == 1 and raw_va.first == DefaultVersionString
              version_array = (raw_va.include?(DefaultVersionString) ? [DefaultVersionString] : []) + raw_va.reject{|v|v == DefaultVersionString}.sort
              mdl.merge!(:versions => version_array.join(", ")) 
            end
          end
          external_ref_source = mdl.delete(:external_ref_source)
          ndx_repo_remotes = mdl.delete(:ndx_repo_remotes)

          if linked_remote = linked_remotes_print_form((ndx_repo_remotes||{}).values,external_ref_source,opts={}) 
            mdl.merge!(:linked_remotes => linked_remote)
          end
        end
        ndx_ret.values
      end
      DefaultVersionString = 'CURRENT'

     private 

      def self.augment_with_remotes_info!(branch_module_rows,module_mh)
        #index by repo_id
        ndx_branch_module_rows = branch_module_rows.inject(Hash.new){|h,r|h.merge(r[:repo][:id] => r)}
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:repo_id,:repo_name,:repo_namespace,:created_at,:is_default],
          :filter => [:oneof, :repo_id, ndx_branch_module_rows.keys]
        }
        Model.get_objs(module_mh.createMH(:repo_remote),sp_hash).each do |r|
          ndx = r[:repo_id]
          (ndx_branch_module_rows[ndx][:ndx_repo_remotes] ||= Hash.new).merge!(r[:id] => r)
        end
        branch_module_rows
      end

      def self.linked_remotes_print_form(repo_remotes,external_ref_source,opts={})
        opts_pp = Opts.new(:dtkn_prefix => true)
        array = 
          if repo_remotes.empty?
            Array.new
          elsif repo_remotes.size == 1
            [repo_remotes.first.print_form(opts_pp)]
          else
            default = RepoRemote.ret_default_remote_repo(repo_remotes)
            repo_remotes.reject!{|r|r[:id] == default[:id]}
            [default.print_form(opts_pp.merge(:is_default_namespace => true))] + repo_remotes.map{|r|r.print_form(opts_pp)}
          end

        array << external_ref_source if external_ref_source

        array.join(JoinDelimiter)
      end
      JoinDelimiter = ', '
    end
  end
end
