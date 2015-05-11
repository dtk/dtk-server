r8_require('../branch_names')
module DTK
  class ModuleBranch < Model
    r8_nested_require('branch','location')
    include BranchNamesMixin
    extend BranchNamesClassMixin

    def self.common_columns()
      [:id,:group_id,:display_name,:branch,:repo_id,:current_sha,:is_workspace,:type,:version,:ancestor_id,:external_ref,:dsl_parsed]
    end

    # TODO: should change type of self[:external_ref] to json
    # but before check any side effect of change
    def external_ref()
      get_field?(:external_ref) && eval(self[:external_ref])
    end

    def external_ref_source()
      if external_ref = external_ref()
        if source = external_ref[:source]
          source.gsub(/ /,'')
        end
      end
    end

    def get_type()
      get_field?(:type).to_sym
    end

    def set_dsl_parsed!(boolean_val)
      update(:dsl_parsed => boolean_val)
    end

    def dsl_parsed?()
      get_field?(:dsl_parsed)
    end

    def get_module_repo_info()
      repo = get_repo(:repo_name)
      module_obj = get_module()
      version = get_field?(:version)
      opts = {:version => version, :module_namespace => module_obj.module_namespace()}
      ModuleRepoInfo.new(repo,module_obj.module_name(),module_obj.id_handle(),self,opts)
    end

    def get_module()
      row = get_obj(:cols => [:type,:parent_info])
      type = row[:type].to_sym
# TODO: temp until for source of bug where component rather than component_module put in for type
if type == :component
  type = :component_module
  Log.error("Bug :component from :component_module on (#{row.inspect})")
end
      row[type]
    end

    def get_module_name()
      get_module().module_name()
    end

    # deletes both local and remore branch
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
      # TODO: in addition to :any_updates or instead can send the updated sha and have client to use that to determine if client is up to date
      return ret if diffs_summary.no_diffs?()
      ret = ret.merge!(:any_updates => true, :fast_forward_change => true)

      result = RepoManager.fast_foward_merge_from_branch(branch_name_to_merge_from,self)
      if result == :merge_needed
        if opts[:force]
          RepoManager.hard_reset_to_branch(branch_name_to_merge_from,self)
          ret.merge!(:fast_forward_change => false)
        else
          raise ErrorUsage.new("There is a merge conflict! Cannot push changes without using the --force option; THIS OPTION WILL WIPE OUT CHANGES IN THE BASE COMPONENT MODULE")
        end
      elsif result != :changed
        raise Error.new("Unexpected result from fast_foward_merge_from_branch")
      end

      self[:current_sha] =  diffs.b_sha
      update(:current_sha => self[:current_sha])

      impl_obj = get_implementation()
      impl_obj.modify_file_assets(diffs_summary)
      if diffs_summary.meta_file_changed?()
        e = ErrorUsage::Parsing.trap(:only_return_error=>true) do
          component_module.parse_dsl_and_update_model(impl_obj,id_handle(),version(),:update_module_refs_from_file => true)
        end
        ret.merge!(:dsl_parsing_errors => e) if e
      end
      ret
    end

    # returns true if actual pull was needed
    def pull_repo_changes?(commit_sha, force = false)
      update_object!(:branch,:current_sha)
      if is_set_to_sha?(commit_sha)
        nil
      else
        merge_result = RepoManager.fast_foward_pull(self[:branch], force, self)
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

    def matches_base_version?()
      matches_version?(BaseVersion)
    end
    BaseVersion = nil
    def matches_version?(version=nil)
      update_object!(:version)
      self[:version] == self.class.version_field(version)
    end

    def incrementally_update_component_dsl(augmented_objects,context={})
      dsl_path,hash_content,fragment_hash = ModuleDSL.incremental_generate(self,augmented_objects,context)
      serialize_and_save_to_repo?(dsl_path,hash_content)
      fragment_hash
    end

    # updates repo if any changes and if so returns new commit_sha
    # args could be either file_path,hash_content,file_format(optional) or single element which is an array
    # having elements with keys :path, :hash_content, :format
    def serialize_and_save_to_repo?(*args)
      opts = Hash.new
      files =
      if args.size == 1
        args[0]
      else
        path,hash_content,format_type,opts = args
        format_type ||= dsl_format_type_form_path(path)
        opts ||= Hash.new
        [{:path => path,:hash_content => hash_content,:format_type => format_type}]
      end

      unless files.empty?
        ambiguous_deps = opts[:ambiguous]||[]
        missing_deps   = opts[:possibly_missing]||[]
        any_changes, new_cmp_refs, valid_existing, existing_names = false, nil, nil, []
        files.each do |file_info|
          content = Aux.serialize(file_info[:hash_content],file_info[:format_type])

          # check if module_refs files exists already
          existing_content = RepoManager.get_file_content({:path => file_info[:path]},self,{:no_error_if_not_found => true})
          file_path        = file_info[:path]

          if existing_content
            existing_c_hash = Aux.convert_to_hash(existing_content,file_info[:format_type])
            if !existing_c_hash.kind_of?(ErrorUsage::Parsing) and existing_c_hash['component_modules']
              valid_existing = true 
            end
          end

          # if module_refs file and content already exist then append new module_refs to existing
          if valid_existing && opts[:update_module_refs] && file_path.eql?("module_refs.#{file_info[:format_type].to_s}")
            existing_c_hash = Aux.convert_to_hash(existing_content,file_info[:format_type])
            new_cmp_refs = file_info[:hash_content].clone

            if new_cmp_refs[:component_modules] && existing_c_hash['component_modules']
              new_cmp_refs[:component_modules].merge!(existing_c_hash['component_modules'])
            end

            content = Aux.serialize(new_cmp_refs,file_info[:format_type]) if new_cmp_refs
          end

          if valid_existing
            existing_c_hash['component_modules'].each do |k,v|
              existing_names << k if v
            end
          end

          unless ambiguous_deps.empty?
            ambiguous = process_ambiguous_dependencies(ambiguous_deps, file_info[:hash_content])
            if file_info[:hash_content].empty?
              content = ambiguous
            else
              if valid_existing
                temp_ambiguous = ambiguous_deps.clone
                temp_ambiguous.delete_if{|ad,n| existing_names.include?(ad.split('/').last)}
                ambiguous = process_ambiguous_dependencies(temp_ambiguous, file_info[:hash_content])
              end
              content << ambiguous
            end
          end

          unless missing_deps.empty?
            missing = process_missing_dependencies(missing_deps, hash_content)
            if file_info[:hash_content].empty?
              content = missing
            else
              if valid_existing
                temp_missing = missing_deps.clone
                temp_missing.delete_if{|md| existing_names.include?(md.split('/').last)}
                missing = process_missing_dependencies(temp_missing, hash_content)
              end
              content << missing
            end
          end

          if file_info[:hash_content].empty? && ambiguous_deps.empty? && missing_deps.empty?
            content = "---\ncomponent_modules:\n" unless valid_existing
          end

          any_change = RepoManager.add_file({:path => file_info[:path]},content,self)
          any_changes = true if any_change
        end
        if any_changes
          new_commit_sha = push_changes_to_repo()
          new_commit_sha
        end
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
      set_sha(commit_sha) # returns commit_sha to calling fn
    end

    def process_ambiguous_dependencies(ambiguous, hash_content)
      content = ""
      content << "---\ncomponent_modules:\n" if hash_content.empty?

      ambiguous.each do |module_name,namespaces|
        name = module_name.to_s.split('/').last
        content << "  #{name}:\n"
        count = 0
        namespaces.each do |val|
          count += 1
          content << "#    namespace: #{val}\n"
          content << "#  -- OR --  \n" if count < namespaces.size
        end
      end

      content
    end

    def process_missing_dependencies(missing, hash_content)
      content = ""
      content << "---\ncomponent_modules:\n" if hash_content.empty?

      missing.each do |module_name|
        name = module_name.to_s.split('/').last
        content << "#  dependency from git import: #{module_name}\n"
        content << "#  #{name}:\n"
        content << "#    namespace: NAMESPACE\n"
      end

      content
    end

    private :push_changes_to_repo

    def default_dsl_format_type()
      index = (get_type() == :service_module ? :service : :component)
      R8::Config[:dsl][index][:format_type][:default].to_sym
    end

    # creates if necessary a new branch from this (so new branch and this branch share history)
    # returns repo for new branch; this just creates repo branch and does not update object model
    # opts can have keys
    #  :sha - sha on base branch to branch from
    def create_new_branch_from_this_branch?(project,base_repo,new_version,opts={})
      branch_name = Location::Server::Local::workspace_branch_name(project,new_version)
      RepoManager.add_branch_and_push?(branch_name,opts,self)
      repo_for_version(base_repo,new_version)
    end

    def repo_for_version(base_repo,version)
      base_repo #bakes in that different versions share same git repo
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

    def get_module_refs()
      sp_hash = {
        :cols => [:id, :display_name, :namespace_info],
        :filter => [:eq, :branch_id, self[:id]]
      }
      Model.get_objs(model_handle(:module_ref),sp_hash)
    end

    def self.get_namespace_info(id_handles)
      ret = Hash.new
      return ret if id_handles.empty?
      sp_hash = {
        :cols => [:id,:component_module_namespace_info],
        :filter => [:oneof,:id,id_handles.map{|idh|idh.get_id}]
      }
      get_objs(id_handles.first.createMH(),sp_hash)
    end
    def get_namespace_info()
      get_obj(:cols => [:component_module_namespace_info])
    end

    def self.get_component_workspace_branches(node_idhs)
      sp_hash = {
    # MOD_RESTRUCT: after get rid of lib branches might use below
#        :cols => [:id,:display_name,:component_ws_module_branches],
        :cols => [:id,:display_name,:component_module_branches], #temp which can return lib branches
        :filter => [:oneof, :id, node_idhs.map{|idh|idh.get_id()}]
      }
      sample_node_idh = node_idhs.first()
      node_rows = get_objs(sample_node_idh.createMH(),sp_hash)
      # get rid of dups
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

    def self.ret_create_hash(repo_idh,local,opts={})
      ancestor_branch_idh = opts[:ancestor_branch_idh]
      branch =  local.branch_name
      type = local.module_type.to_s
# TODO: temp until for source of bug where component rather than component_module put in for type
if type == 'component'
  type = 'component_module'
  Log.error_pp(["Bug :component from :component_module on",local,caller()[0..7]])
end

      assigns = {
        :display_name => branch,
        :branch       => branch,
        :repo_id      => repo_idh.get_id(),
        :is_workspace => true,
        :type         => local.module_type.to_s,
        :version      => version_field(local.version)
      }
      assigns.merge!(:ancestor_id => ancestor_branch_idh.get_id()) if ancestor_branch_idh
      ref = branch
      {ref => assigns}
    end
    # TODO: ModuleBranch::Location: deprecate below for above
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

    # TODO: clean up; complication is that an augmented branch can be passed
    def repo_and_branch()
      repo = self[:repo]
      cols = (self[:repo] ? [:branch] : [:branch,:repo_id])
      update_object!(*cols)
      unless repo
        sp_hash = {
          :cols => [:id,:display_name, :repo_name],
          :filter => [:eq,:id,self[:repo_id]]
        }
        repo = Model.get_obj(model_handle(:repo),sp_hash)
      end
      repo_name = repo[:repo_name]||repo[:display_name]
      [repo_name,self[:branch]]
    end

    # in case we change what schema the module and branch objects under
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
