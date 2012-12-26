r8_require('branch_names')
module DTK
  class ModuleBranch < Model
    include BranchNamesMixin
    extend BranchNamesClassMixin

    def get_type()
      update_object!(:type)[:type].to_sym
    end

    def pp_version()
      update_object!(:version)
      (self[:version] == BranchNameDefaultVersion) ? nil : self[:version]
    end

    #this adds library branch from this, which is a workspace branch
    def add_library_branch?(new_lib_branch_name)
      RepoManager.add_branch_and_push_to_origin?(new_lib_branch_name,self)
    end

    #this adds ws branch from this, which is a lib branch
    def add_workspace_branch?(new_ws_branch_name)
      RepoManager.add_branch_and_push_to_origin?(new_ws_branch_name,self)
    end

    #args could be either file_path,hash_content,file_format(optional) or single element which is an array having elements with keys :path, :hash_content, :format 
    def serialize_and_save_to_repo(*args)
      files = 
      if args.size == 1
        args[0]
      else
        [{:path => args[0],:hash_content => args[1],:format_type => args[2]||default_dsl_format_type()}]
      end
      unless files.empty?
        files.each do |file_info|
          content = Aux.serialize(file_info[:hash_content],file_info[:format_type])
          RepoManager.add_file({:path => file_info[:path]},content,self)
        end
        RepoManager.push_changes(self)
      end
    end
    
    def default_dsl_format_type()
      index = (get_type() == :service_module ? :service : :component)
      R8::Config[:dsl][index][:format_type][:default].to_sym
    end

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
      def version_field(version=nil)
        version || "master"
      end

      def get_augmented_workspace_branch(module_obj,version=nil,opts={})
        sp_hash = {
          :cols => cols_for_matching_library_branches(module_obj.module_type()),
          :filter => [:and,[:eq, module_id_col(module_obj.module_type()),module_obj.id()], 
                      [:eq,:is_workspace,true],
                      [:eq,:version,version_field(version)]]
        }
        aug_ws_branch_rows = get_objs(module_obj.model_handle(:module_branch),sp_hash)
        if aug_ws_branch_rows.empty? and opts[:no_error_if_none].nil?
          raise ErrorUsage.new("Module workspace (#{module_obj.pp_module_name(version)}) does not exist")
        elsif aug_ws_branch_rows.size > 1
          raise Error.new("error in finding unique workspace branch from component module (#{module_obj.pp_module_name(version)})")
        end
        aug_ws_branch_rows.first
      end

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
  
    def create_workspace_branch?(module_type,project)
      module_id_col = module_id_col(module_type)
      update_object!(module_id_col,:version,:repo_id,:type)

      ref = branch = workspace_branch_name(project)
      match_assigns = {
        module_id_col => self[module_id_col],
        :project_id =>  project.id_handle.get_id(),
        :version => self[:version]
      }
      other_assigns = {
        :display_name => branch,
        :branch => branch,
        :repo_id => self[:repo_id],
        :is_workspace => true,
        :type => self[:type]

      }
      branch_mh = model_handle.merge(:parent_model_name => module_type)
      mb_idh = Model.create_from_row?(branch_mh,ref,match_assigns,other_assigns) do
        #called only if row is created
        new_ws_branch_name = branch
        add_workspace_branch?(new_ws_branch_name)
      end
      mb_idh.create_object().merge(match_assigns).merge(other_assigns)
    end

    def self.get_component_workspace_branches(node_idhs)
      sp_hash = {
        :cols => [:id,:display_name,:component_ws_module_branches],
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

    def self.ret_lib_create_hash(parent_model_name,library_idh,repo_idh,version=nil)
      branch =  library_branch_name(library_idh,version)
      assigns = {
        :display_name => branch,
        :branch => branch,
        :repo_id => repo_idh.get_id(),
        :is_workspace => false,
        :type => parent_model_name.to_s
      }
      assigns[:version] = version||BranchNameDefaultVersion
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
