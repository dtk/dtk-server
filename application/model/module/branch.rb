r8_require('../branch_names')
module DTK
  class ModuleBranch < Model
    include BranchNamesMixin
    extend BranchNamesClassMixin

    def self.common_columns()
      [:id,:group_id,:display_name,:branch,:repo_id,:current_sha,:is_workspace,:type,:version,:ancestor_id,:external_ref]
    end

    def get_type()
      update_object!(:type)[:type].to_sym
    end

    def get_module_repo_info()
      repo = get_repo(:repo_name)
      module_obj = get_module()
      version = get_field?(:version)
      ModuleRepoInfo.new(repo,module_obj.module_name(),module_obj.id_handle(),self,version)
    end

    def get_module()
      row = get_obj(:cols => [:type,:parent_info])
      type = row[:type].to_sym
      row[type]
    end

    def get_module_name()
      get_module().module_name()
    end

    #deletes both local and remore branch
    def delete_instance_and_repo_branch()
      RepoManager.delete_branch(self)
      delete_instance(id_handle())
    end

    def update_current_sha_from_repo!()
      current_sha = RepoManager.branch_head_sha(self)
      update(:current_sha => current_sha)
      self[:current_sha] = current_sha
      current_sha
    end

    def update_external_ref(ext_ref)
      update(:external_ref => ext_ref.to_s)
      self[:external_ref] = ext_ref
    end

    def merge_changes_and_update_model?(component_module,branch_name_to_merge_from,opts={})
      ret = get_module_repo_info()
      diffs = RepoManager.diff(branch_name_to_merge_from,self)
      diffs_summary = diffs.ret_summary()
      #TODO: in addition to :any_updates or instead can send the updated sha and have client to use that to determine if client is up to date
      return ret if diffs_summary.no_diffs?()
      ret = ret.merge!(:any_updates => true, :fast_forward_change => true)

      result = RepoManager.fast_foward_merge_from_branch(branch_name_to_merge_from,self)
      if result == :merge_needed
        if opts[:force]
          RepoManager.hard_reset_to_branch(branch_name_to_merge_from,self)
          ret.merge!(:fast_forward_change => false)
        else
          raise ErrorUsage.new("Cannot push changes without using the --force option; THIS OPTION WILL WIPE OUT CHANGES IN THE BASE COMPONENT MODULE")
        end
      elsif result != :changed
        raise Error.new("Unexpected result from fast_foward_merge_from_branch")
      end

      self[:current_sha] =  diffs.b_sha
      update(:current_sha => self[:current_sha])

      impl_obj = get_implementation()
      impl_obj.modify_file_assets(diffs_summary)
      if diffs_summary.meta_file_changed?()
        if e = ErrorUsage::Parsing.trap{component_module.parse_dsl_and_update_model(impl_obj,id_handle())}
          ret.merge!(:dsl_parsing_errors => e) 
        end
      end
      ret
    end

    #returns true if actual pull was needed
    def pull_repo_changes?(commit_sha)
      update_object!(:branch,:current_sha)
      if is_set_to_sha?(commit_sha)
        nil
      else
        merge_result = RepoManager.fast_foward_pull(self[:branch],self)
        if merge_result == :merge_needed
          raise Error.new("Merge problem exists between multiple clients editting the module (#{get_module().pp_module_name()})")
        end
        set_sha(commit_sha)
        true
      end
    end

    def is_set_to_sha?(commit_sha)
      commit_sha == get_field?(:current_sha)
    end
    def set_sha(commit_sha)
      update(:current_sha => commit_sha)
      commit_sha
    end

    def version()
      self.class.version_from_version_field(get_field?(:version))
    end
    def assembly_module_version?()
      version_obj = version()
      if version_obj.kind_of?(ModuleVersion::AssemblyModule)
        version_obj
      end
    end

    def version_print_form(opts=Opts.new)
      default_version_string = opts[:default_version_string] # can be null
      update_object!(:version)
      has_default_version?() ? default_version_string : self[:version] 
    end

    def matches_version?(version=nil)
      update_object!(:version)
      self[:version] == self.class.version_field(version)
    end

    def incrementally_update_component_dsl(augmented_objects,context={})
      dsl_path,hash_content,fragment_hash = ComponentDSL.incremental_generate(self,augmented_objects,context)
      serialize_and_save_to_repo(dsl_path,hash_content)
      fragment_hash
    end

    #args could be either file_path,hash_content,file_format(optional) or single element which is an array having elements with keys :path, :hash_content, :format 
    def serialize_and_save_to_repo(*args)
      files = 
      if args.size == 1
        args[0]
      else
        path,hash_content,format_type = args
        [{:path => path,:hash_content => hash_content,:format_type => format_type||dsl_format_type_form_path(path)}]
      end
      unless files.empty?
        any_changes = false
        files.each do |file_info|
          content = Aux.serialize(file_info[:hash_content],file_info[:format_type])
          any_change = RepoManager.add_file({:path => file_info[:path]},content,self)
          any_changes = true if any_change 
        end
        push_changes_to_repo() if any_changes
      end
    end

    def dsl_format_type_form_path(path)
      extension = (path =~ /\.([^\.]+$)/; $1)
      unless ret = FormatTypeFromExtension[extension]
        raise Error.new("Cannot find format type from file path (#{path})")
      end
      ret
    end
    private :dsl_format_type_form_path
    FormatTypeFromExtension = {
      "json" => :json,
      "yaml" => :yaml
    }

    def push_changes_to_repo()
      commit_sha = RepoManager.push_changes(self)
      set_sha(commit_sha)
    end
    private :push_changes_to_repo

    def default_dsl_format_type()
      index = (get_type() == :service_module ? :service : :component)
      R8::Config[:dsl][index][:format_type][:default].to_sym
    end

    #creates if necessary a new branch from this (so new branch and this branch share history)
    #returns repo for new branch; this just creates repo branch and does not update object model
    def create_new_branch_from_this_branch?(project,base_repo,new_version)
      branch_name = self.class.workspace_branch_name(project,new_version)
      RepoManager.add_branch_and_push?(branch_name,self)
      repo_for_version(base_repo,new_version)
    end

    def repo_for_version(base_repo,version)
      base_repo #bakes in that different versions share same git repo
    end

    #MOD_RESTRUCT: TODO: deprecate 
    def self.update_library_from_workspace?(ws_branches,opts={})
      ws_branches = [ws_branches] unless ws_branches.kind_of?(Array)
      ret = Array.new
      return ret if ws_branches.empty?
      if opts[:ws_branch_augmented]
        matching_branches = ws_branches
      else
        sample_ws_branch = ws_branches.first
        type = sample_ws_branch.get_type()
        sp_hash = {
          :cols => cols_for_matching_library_branches(type),
          :filter => [:oneof, :id, ws_branches.map{|r|r.id_handle().get_id()}]
        }
        matching_branches =  get_objs(sample_ws_branch.model_handle(),sp_hash)
      end
      if matching_branches.find{|r|r[:library_module_branch][:repo_id] != r[:repo_id]}
        raise Error.new("Not implemented: case when ws and library branch differ in refering to distinct repos")
      end
      matching_branches.map{|augmented_branch|update_library_from_workspace_aux?(augmented_branch)}
    end
    #TODO: better collapse above and below
    def self.update_workspace_from_library?(ws_branch_obj,lib_branch_obj,opts={})
      ws_branch_obj.update_object!(:repo_id)
      lib_branch_obj.update_object!(:repo_id,:branch)
      if ws_branch_obj[:repo_id] != lib_branch_obj[:repo_id]
        raise Error.new("Not implemented: case when ws and library branch differ in refering to distinct repos")
      end
      ws_impl = ws_branch_obj.get_implementation()
      update_target_from_source?(ws_branch_obj,ws_impl,lib_branch_obj[:branch])
    end

    def self.cols_for_matching_library_branches(type)
      matching_lib_branches_col = (type.to_s == "component_module" ? :matching_component_library_branches : :matching_service_library_branches)
      [:id,:repo_id,:version,:branch,module_id_col(type),matching_lib_branches_col]
    end

    def self.get_component_modules_info(module_branch_idhs)
      ret = Array.new
      return ret if module_branch_idhs.nil? or module_branch_idhs.empty?
      sp_hash = {
        :cols => [:component_module_info],
        :filter => [:oneof,:id,module_branch_idhs.map{|idh|idh.get_id()}]
      }
      sample_mb_idh = module_branch_idhs.first
      get_objs(sample_mb_idh.createMH(),sp_hash).map do |r|
        r[:component_module].merge(:repo => r[:repo])
      end
    end

    def get_implementation(*added_cols)
      update_object!(:repo_id,:branch)
      cols = [:id,:display_name,:repo,:branch,:group_id]
      cols += added_cols unless added_cols.empty?
      sp_hash = {
        :cols => cols,
        :filter => [:and,[:eq, :repo_id, self[:repo_id]],[:eq, :branch, self[:branch]]]
      }
      Model.get_obj(model_handle(:implementation),sp_hash)
    end

    def get_repo(*added_cols)
      update_object!(:repo_id)
      cols = [:id,:display_name]
      cols += added_cols unless added_cols.empty?
      sp_hash = {
        :cols => cols,
        :filter => [:eq, :id, self[:repo_id]]
      }
      Model.get_obj(model_handle(:repo),sp_hash)
    end

    def get_service_module()
      row = get_obj(:cols => [:service_module])
      row && row[:service_module]
    end

    def get_assemblies()
      get_objs(:cols => [:assemblies]).map{|r|r[:component]}
    end

    class << self
     private
      def update_library_from_workspace_aux?(augmented_branch)
        lib_branch_obj = augmented_branch[:library_module_branch]
        lib_branch_augment = {
          :workspace_module_branch => Aux::hash_subset(augmented_branch,[:id,:repo_id]),
        }
        ret = lib_branch_obj.merge(lib_branch_augment)
        ws_branch_name = augmented_branch[:branch]
        #determine if there is any diffs between workspace and library branches
        diff = RepoManager.diff(ws_branch_name,lib_branch_obj)
        diff_summary = diff.ret_summary()
        if diff_summary.no_diffs?()
          return ret
        end
        unless diff_summary.no_added_or_deleted_files?()
          #find matching implementation and modify file assets
          augmented_branch[:implementation].modify_file_assets(diff_summary)
        end
        if diff_summary.meta_file_changed?()
          component_dsl = ComponentDSL.create_dsl_object_from_impl(augmented_branch[:implementation])
          component_dsl.update_model()
        end

        #update the repo
        RepoManager.merge_from_branch(ws_branch_name,lib_branch_obj)
        RepoManager.push_implementation(lib_branch_obj)
        ret
      end
      #TODO: use below as basis to rewrite above
      def update_target_from_source?(target_branch_obj,target_impl,source_branch_name)
        #determine if there is any diffs between source and target branches
        diff = RepoManager.diff(source_branch_name,target_branch_obj)
        diff_summary = diff.ret_summary()
        return if diff_summary.no_diffs?()

        unless diff_summary.no_added_or_deleted_files?()
          #find matching implementation and modify file assets
          target_impl.modify_file_assets(diff_summary)
        end
        if diff_summary.meta_file_changed?()
          component_dsl = ComponentDSL.create_dsl_object_from_impl(target_impl)
          component_dsl.update_model()
        end
      
        #update the repo
        RepoManager.merge_from_branch(source_branch_name,target_branch_obj)
        RepoManager.push_implementation(target_branch_obj)
      end
    end
  
    def self.get_component_workspace_branches(node_idhs)
      sp_hash = {
    #MOD_RESTRUCT: after get rid of lib branches might use below
#        :cols => [:id,:display_name,:component_ws_module_branches],
        :cols => [:id,:display_name,:component_module_branches], #temp which can return lib branches
        :filter => [:oneof, :id, node_idhs.map{|idh|idh.get_id()}]
      }
      sample_node_idh = node_idhs.first()
      node_rows = get_objs(sample_node_idh.createMH(),sp_hash)
      #get rid of dups 
      node_rows.inject(Hash.new) do |h,r|
        module_branch = r[:module_branch]
        h[module_branch[:id]] ||= module_branch
        h
      end.values
    end

    def get_ancestor_branch?()
      ret = nil
      unless ancestor_branch_id = get_field?(:ancestor_id)
        return ret
      end
      sp_hash = {
        :cols => self.class.common_columns(),
        :filter => [:eq,:id,ancestor_branch_id]
      }
      Model.get_obj(model_handle(),sp_hash)
    end

    def self.ret_workspace_create_hash(project,type,repo_idh,opts={})
      version = opts[:version]
      ancestor_branch_idh = opts[:ancestor_branch_idh]
      branch =  workspace_branch_name(project,version)
      assigns = {
        :display_name => branch,
        :branch => branch,
        :repo_id => repo_idh.get_id(),
        :is_workspace => true,
        :type => type,
        :version => version_field(version)
      }
      assigns.merge!(:ancestor_id => ancestor_branch_idh.get_id()) if ancestor_branch_idh
      ref = branch
      {ref => assigns}
    end
    #MOD_RESTRUCT: TODO: deprecate below for above
    def self.ret_lib_create_hash(parent_model_name,library_idh,repo_idh,version=nil)
      branch =  library_branch_name(library_idh,version)
      assigns = {
        :display_name => branch,
        :branch => branch,
        :repo_id => repo_idh.get_id(),
        :is_workspace => false,
        :type => parent_model_name.to_s,
        :version =>version_field(version)
      }
      ref = branch
      {ref => assigns}
    end

    #TODO: clean up; complication is that an augmented branch can be passed
    def repo_and_branch()
      repo = self[:repo]
      cols = (self[:repo] ? [:branch] : [:branch,:repo_id])
      update_object!(*cols)
      unless repo
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:eq,:id,self[:repo_id]]
        }
        repo = Model.get_obj(model_handle(:repo),sp_hash)
      end
      repo_name = repo[:repo_name]||repo[:display_name]
      [repo_name,self[:branch]]
    end

    #in case we change what schema the module and branch objects under
    def self.module_id_col(module_type)
      case module_type
        when :service_module then :service_id
        when :component_module then :component_id
        else raise Error.new("Unexected module type (#{module_type})")
      end
    end
    def module_id_col(module_type)
      self.class.module_id_col(module_type)
    end
  end
end
