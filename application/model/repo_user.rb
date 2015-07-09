module DTK
  class RepoUser < Model
    SSH_KEY_EXISTS = 'Provided RSA public key already exists for another user'

    ### Attributes ###

    def self.common_columns
      [:id,
       :group_id,
       :username,
       :type,
       :index,
       :ssh_rsa_pub_key,
       :component_module_direct_access,
       :service_module_direct_access,
       :repo_manager_direct_access
      ]
    end

    ### Instance methods ###

    # Returns flag which indicates if this user has been created on Repoman
    #
    def has_repoman_direct_access?
      self[:repo_manager_direct_access]
    end

    def owner
      self.update_object!(:owner_id)
      User.get_user_by_id(self.model_handle(:user), self[:owner_id])
    end

    def rsa_key_name
      self.update_object!(:display_name) unless self[:display_name]
      self[:display_name]
    end

    def rsa_pub_key
      self.update_object!(:ssh_rsa_pub_key) unless self[:ssh_rsa_pub_key]
      self[:ssh_rsa_pub_key]
    end

    def owner_username
      owner.username
    end

    # Returns flag which indicates if this user has access to component_modules or service_modules
    #
    def has_direct_access?(module_model_name,opts={})
      direct_access_col = direct_access_col(module_model_name)
      update_object!(direct_access_col) unless opts[:donot_update]
      self[direct_access_col]
    end

    # Returns flag which indicates if there is direct access in exception to provided in param
    #
    def any_direct_access_except?(module_model_name)
       case module_model_name
        when :component_module then has_direct_access?(:service_module)
        when :service_module then has_direct_access?(:component_module)
        else raise Error.new("Illegal module model name (#{module_model_name})")
      end
    end

    # Updates flag for direct access
    # Params:
    #   module_model_name (sym)
    #   val (boolean)
    #
    def update_direct_access(module_model_name,val)
      direct_access_col = direct_access_col(module_model_name)
      update(direct_access_col => val)
      self[direct_access_col] = val
      self
    end

    ### Class methods ###

    # Find user by SSH PUB key
    #
    def self.match_by_ssh_rsa_pub_key!(mh, ssh_rsa_pub_key)
      ret = find_by_pub_key(mh, ssh_rsa_pub_key)

      unless ret
        raise ErrorUsage.new('The SSH public key for the client machine has not been registered, have you added SSH key for this client?')
      end

      ret
    end

    def self.find_by_pub_key(model_handle, ssh_rsa_pub_key)
      sp_hash = {
        cols: common_columns(),
        filter: [:eq, :ssh_rsa_pub_key, ssh_rsa_pub_key]
      }

      get_obj(model_handle.createMH(:repo_user), sp_hash)
    end

    def self.authorized_users_acls(model_handle)
      authorized_users(model_handle).map do |repo_username|
        {
          repo_username: repo_username,
          access_rights: AuthorizedUserDefaultRights
        }
      end
    end
    AuthorizedUserDefaultRights = 'RW+'
    def self.authorized_users(model_handle)
      get_objs(model_handle.createMH(:repo_user), cols: [:id,:username]).map{|r|r[:username]}
    end
    private_class_method :authorized_users

    # returns an object or calls block (with new or existing object)
    def self.add_repo_user?(repo_user_type, repo_user_mh, ssh_rsa_keys={},username=nil)
      # for match on type; use following logic
      # if ssh public key given look for match on this
      # otherwise return error if there is multiple matches for node or admin type
      existing_users = get_existing_repo_users(repo_user_mh, type: repo_user_type.to_s)
      if ssh_rsa_pub_key = ssh_rsa_keys[:public]
        match = existing_users.find{|r|r[:ssh_rsa_pub_key] == ssh_rsa_pub_key}
        return match, true if match

        # get all public key files from gitolite_admin keydir
        # and raise exception if file with provided rsa_public_key exists already
        gitolite_admin_keydir = RepoManager.get_keydir()
        pub_keys = Dir.entries(gitolite_admin_keydir).select{|key| key.to_s.include?('.pub')}

        pub_keys.each do |key|
          key_content = File.read("#{gitolite_admin_keydir}/#{key}")
          if (key_content == ssh_rsa_pub_key)
            Log.info("Provided RSA public key already exists for another user, other user's keydir (#{key})")
            raise ErrorUsage.new(SSH_KEY_EXISTS)
          end
        end
      else
        case existing_users.size
         when 0
         when 1
          return existing_users.first
         else
          if [:admin,:node].include?(repo_user_type)
            raise Error.new("Unexpected to have multiple matches of repo user type (#{repo_user_type})")
          end
        end
      end

      add_repo_user(repo_user_type,repo_user_mh,ssh_rsa_keys,existing_users,username)
    end

    # ssh_rsa_keys[:public].nil? means that expected that key already exists in the gitolite admin db
    def self.add_repo_user(repo_user_type,repo_user_mh,ssh_rsa_keys={},existing_users=[],username=nil)
      repo_username,index =  ret_new_repo_username_and_index(repo_user_type,existing_users,username)
      if ssh_rsa_keys[:public]
        RepoManager.add_user(repo_username,ssh_rsa_keys[:public],noop_if_exists: true)
      end
      create_instance(repo_user_mh,repo_user_type,repo_username,index,ssh_rsa_keys)
    end

    def self.get_matching_repo_users(repo_user_mh,filters_keys,_username,cols=nil)
      repo_users = get_existing_repo_users(repo_user_mh,filters_keys,cols)
    end

    def self.get_matching_repo_user(repo_user_mh,filters_keys,cols=nil)
      ret = nil
      repo_users = get_existing_repo_users(repo_user_mh,filters_keys,cols)
      if repo_users.size > 1
        Log.error("Unexpected to have multiple matches of repo user when matching on (#{filters_keys.inspect})")
      end
      repo_users.first
    end

    def self.get_by_repo_username(model_handle,repo_username)
      sp_hash = {
        cols: [:id,:username,:repo_manager_direct_access],
        filter: [:eq,:username,repo_username]
      }
      get_obj(model_handle,sp_hash)
    end

    private

    ### Private instance methods ###

    def direct_access_col(module_model_name)
      case module_model_name
       when :component_module then :component_module_direct_access
       when :service_module then :service_module_direct_access
       else raise Error.new("Illegal module model name (#{module_model_name})")
      end
    end

    ### Private class methods ###

    def self.get_existing_repo_users(repo_user_mh, filter_keys={}, cols=nil)
      sp_hash = {
        cols: cols ? (cols+[:id,:group_id]) : common_columns()
      }
      unless filter_keys.empty?
        filter_list = filter_keys.map{|k,v|[:eq,k,v.to_s]}
        sp_hash[:filter] = (filter_list.size == 1 ? filter_list.first : ([:and] + filter_list))
      end
      get_objs(repo_user_mh,sp_hash)
    end

    def self.ret_new_repo_username_and_index(type,existing_matches,username)
      if type == :admin
        # TODO: r8sserver will eb deprecated
        new_repo_username = R8::Config[:admin_repo_user]||"dtk-admin-#{R8::Config[:dtk_instance_user]}"
        new_index = 1
      elsif username
        new_repo_username = username
        new_index = 0
      else
        max = 0
        existing_matches.each do |m|
          if m[:index] > max
            max = m[:index]
          end
        end
        new_index = max+1
        suffix = (new_index == 1 ? '' : "-#{new_index}")
        username = CurrentSession.new.get_username()
        new_repo_username = "dtk-#{type}-#{username}#{suffix}"
      end
      [new_repo_username,new_index]
    end

    def self.create_instance(model_handle,type,repo_username,index,ssh_rsa_keys={})
      create_row = {
        ref: repo_username,
        display_name: repo_username,
        username: repo_username,
        index: index,
        type: type.to_s,
        ssh_rsa_pub_key: ssh_rsa_keys[:public],
        ssh_rsa_private_key: ssh_rsa_keys[:private]
      }
      new_idh = create_from_row(model_handle,create_row)
      new_idh.create_object.merge(create_row)
    end
  end
end
