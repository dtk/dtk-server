module DTK
	module AutoImport
		def get_required_and_missing_modules(project, remote_params, client_rsa_pub_key=nil)
		  remote = remote_params.create_remote(project)
		  response = Repo::Remote.new(remote).get_remote_module_components(client_rsa_pub_key)
		  opts = Opts.new(:project_idh => project.id_handle())

		  # this method will return array with missing and required modules
		  module_info_array = self.cross_reference_modules(opts, response['component_info'], remote.namespace)
		  module_info_array.push(response['dependency_warnings'])
		end

		# Method will check if given component modules are present on the system
		# returns [missing_modules, found_modules]
		def cross_reference_modules(opts, required_modules, service_namespace)
		  project_idh = opts.required(:project_idh)

		  required_modules ||= []
		  req_names = required_modules.collect { |m| m['module_name']}

		  missing_modules, found_modules = [], []

		  required_modules.each do |r_module|
		    name      = r_module["module_name"]
		    type      = r_module["module_type"]
		    version   = r_module["version_info"]
		    namespace = r_module["remote_namespace"]

		    is_found = installed_modules(type.to_sym, req_names, project_idh).find do |i_module|
		      name.eql?(i_module[:display_name]) and
		      ModuleVersion.versions_same?(version, i_module.fetch(:module_branch,{})[:version]) and
		      (namespace.nil? or namespace.eql?(i_module.fetch(:repo_remote,{})[:repo_namespace]))
		    end
		    data = { :name => name, :version => version, :type => type, :namespace => namespace||service_namespace}
		    if is_found
		      found_modules << data
		    else
		      missing_modules << data
		    end
		  end

		  # important
		  clear_cached()

		  [missing_modules, found_modules]
		end

		def clear_cached()
			@cached_module_list = {}
		end

		def installed_modules(type, req_names, project_idh)
			@cached_module_list ||= {}

			unless @cached_module_list[type]
				sp_hash = {
				  :cols => [:id, :display_name, :remote_repos].compact,
				  :filter => [:and,[:oneof, :display_name, req_names],[:eq, :project_project_id, project_idh.get_id()]]
				}
				mh = project_idh.createMH(type)
				@cached_module_list[type] = get_objs(mh,sp_hash)
			end

			@cached_module_list[type]
		end

	end
end

