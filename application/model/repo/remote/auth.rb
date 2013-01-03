module DTK; class Repo 
  class Remote
    module AuthMixin
      def check_remote_auth(mh,remote_params,rsa_pub_key,access_rights,version=nil)
        module_name = remote_params[:module_name]
        type = type_for_remote_module(remote_params[:module_type])
        #TODO: stub tht gives all users complete access
        #TODO: should query first
        authorize_end_user(mh,module_name,type,rsa_pub_key,access_rights)
        #TODO: stub for testing
        get_module_info(remote_params)
      end

      def authorize_dtk_instance(module_name,type)
        username = dtk_instance_remote_repo_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()
        access_rights = "RW+"
        authorize_user(username,rsa_pub_key,access_rights,module_name,type)
      end

      def authorize_end_user(mh,module_name,type,rsa_pub_key,access_rights)
        username = get_end_user_remote_repo_username(mh,rsa_pub_key)
        authorize_user(username,rsa_pub_key,access_rights.remote_repo_form(),module_name,type)
      end

     private 
      def authorize_user(username,rsa_pub_key,access_rights,module_name,type)
        client.create_user(username,rsa_pub_key,:update_if_exists => true)
        grant_user_rights_params = {
          :name => module_name,
          :namespace => DefaultsNamespace,
          :type => type_for_remote_module(type),
          :username => username,
          :access_rights => access_rights
        }
        client.grant_user_access_to_module(grant_user_rights_params)
        module_name
      end

    end

    class AccessRights
      class R < self
        def self.remote_repo_form()
          "R"
        end
      end
      class RW < self
        def self.remote_repo_form()
          "RW+"
        end
      end
    end
  end
end; end
