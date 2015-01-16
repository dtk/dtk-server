module DTK
  module ModuleMixins
    module GetBranchMixin
      def get_module_branch_from_local_params(local_params)
        self.class.get_module_branch_from_local(local_params.create_local(get_project()))
      end
      
      def get_module_branches()
        get_objs_helper(:module_branches,:module_branch)
      end
      
      def get_module_branch_matching_version(version=nil)
        get_module_branches().find{|mb|mb.matches_version?(version)}
      end
      
      def get_workspace_branch_info(version=nil,opts={})
        if aug_branch = get_augmented_workspace_branch({:filter => {:version => version}}.merge(opts))
          module_name = aug_branch[:module_name]
          module_namespace = aug_branch[:module_namespace]
          opts_info = {:version=>version, :module_namespace=>module_namespace}
          ModuleRepoInfo.new(aug_branch[:repo],module_name,id_handle(),aug_branch,opts_info)
        end
      end

      def get_augmented_workspace_branch(opts={})
        version = (opts[:filter]||{})[:version]
        version_field = ModuleBranch.version_field(version) #version can be nil
        sp_hash = {
          :cols => [:display_name,:workspace_info_full,:namespace]
        }
        module_rows = get_objs(sp_hash).select do |r|
          r[:module_branch][:version] == version_field
        end

        if module_rows.size == 0
          unless opts[:donot_raise_error]
            raise ErrorUsage.new("Module #{pp_module_name(version)} does not exist")
          end
          return nil
        end
        
        # aggregate by remote_namespace, filtering by remote_namespace if remote_namespace is given
        unless module_obj = aggregate_by_remote_namespace(module_rows,opts)
          raise ErrorUsage.new("The module (#{pp_module_name(version)}) is not tied to namespace '#{opts[:filter][:remote_namespace]}' on the repo manager")
        end
        
        ret = module_obj[:module_branch].merge(:repo => module_obj[:repo],:module_name => module_obj[:display_name], :module_namespace => module_obj[:namespace][:display_name])
        if opts[:include_repo_remotes]
          ret.merge!(:repo_remotes => module_obj[:repo_remotes])
        end
        ret
      end

      # TODO: :library call should be deprecated
      # type is :library or :workspace
      def find_branch(type,branches)
        matches =
          case type
          when :library then branches.reject{|r|r[:is_workspace]}
          when :workspace then branches.select{|r|r[:is_workspace]}
          else raise Error.new("Unexpected type (#{type})")
          end
      if matches.size > 1
        Error.new("Unexpected that there is more than one matching #{type} branches")
      end
        matches.first
      end

    end

    module GetBranchClassMixin
      def get_module_branch_from_local(local)
        project = local.project()
        project_idh = project.id_handle()
        module_match_filter =
          if local_namespace = local.module_namespace_name()
            [:eq, :ref, Namespace.module_ref_field(local.module_name(),local_namespace)]
          else
            [:eq, :display_name, local.module_name]
          end
        filter = [:and, module_match_filter, [:eq, :project_project_id, project_idh.get_id()]]
        branch = local.branch_name()
        post_filter = proc{|mb|mb[:branch] == branch}
        matches = get_matching_module_branches(project_idh,filter,post_filter)
        if matches.size == 0
          nil
        elsif matches.size == 1
          matches.first
        elsif matches.size > 1
          raise Error.new("Matched rows has unexpected size (#{matches.size}) since its is >1")
        end
      end
      # TODO: ModuleBranch::Location: deprecate below for above
      def get_workspace_module_branch(project,module_name,version=nil,namespace=nil,opts={})
        project_idh = project.id_handle()
        filter  = [:and, [:eq, :display_name, module_name], [:eq, :project_project_id, project_idh.get_id()]]
        filter = filter.push([:eq, :namespace_id, namespace.id()]) if namespace
        branch = ModuleBranch.workspace_branch_name(project,version)
        post_filter = proc{|mb|mb[:branch] == branch}
        matches = get_matching_module_branches(project_idh,filter,post_filter,opts)
        if matches.size == 0
          nil
        elsif matches.size == 1
          matches.first
        elsif matches.size > 1
          Log.error_pp(["Matched rows:",matches])
          raise Error.new("Matched rows has unexpected size (#{matches.size}) since its is >1")
        end
      end
      
      def get_workspace_module_branches(module_idhs)
        ret = Array.new
        if module_idhs.empty?
          return ret
        end
        mh = module_idhs.first.createMH()
        filter = [:oneof,:id,module_idhs.map{|idh|idh.get_id()}]
        post_filter = proc{|mb|!mb.assembly_module_version?()}
        get_matching_module_branches(mh,filter,post_filter)
      end
      
      def get_matching_module_branches(mh_or_idh,filter,post_filter=nil,opts={})
        sp_hash = {
            :cols => [:id,:display_name,:group_id,:module_branches],
          :filter => filter
        }
        rows = get_objs(mh_or_idh.create_childMH(module_type()),sp_hash).map do |r|
          r[:module_branch].merge(:module_id => r[:id])
        end
        if rows.empty?
          return Array.new if opts[:no_error_if_does_not_exist]
          raise ErrorUsage.new("Module does not exist")
        end
        post_filter ? rows.select{|r|post_filter.call(r)} : rows
      end
      
    end
  end
end



