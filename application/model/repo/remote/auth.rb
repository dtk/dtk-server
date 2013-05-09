module DTK; class Repo 
  class Remote
    module AuthMixin
      # TODO: stub tht gives all users complete access
      def raise_error_if_no_access(mh,remote_params,access_rights,opts={})
        module_name = remote_params[:module_name]
        type = type_for_remote_module(remote_params[:module_type])
        
        if opts[:rsa_pub_key]
          namespace = extract_namespace(remote_params[:remote_repo_name])
          authorize_end_user(mh, module_name, namespace, type, opts[:rsa_pub_key], access_rights)
        end
        true
      end

      def authorize_dtk_instance(module_name, module_namespace, type)
        username = dtk_instance_remote_repo_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()
        access_rights = "RW+"
        authorize_user(username,rsa_pub_key,access_rights,module_name,module_namespace,type)
      end

      def authorize_end_user(mh,module_name,module_namespace,type,rsa_pub_key,access_rights)
        username = get_end_user_remote_repo_username(mh,rsa_pub_key)
        authorize_user(username,rsa_pub_key,access_rights.remote_repo_form(),module_name,module_namespace,type)
      end

     private 
      def authorize_user(username,rsa_pub_key,access_rights,module_name,module_namespace,type)
        client.create_user(username,rsa_pub_key,:update_if_exists => true)
        grant_user_rights_params = {
          :name => module_name,
          :namespace => module_namespace || DefaultsNamespace,
          :type => type_for_remote_module(type),
          :username => username,
          :access_rights => access_rights
        }
        client.grant_user_access_to_module(grant_user_rights_params)
        module_name
      end

      # matches namespace from the name remote_repo e.g. "dtk"
      def extract_namespace(remote_repo_name)
        remote_repo_name.nil? ? nil : remote_repo_name.scan(/\A.*?(?=--)/).first
      end

    end

    class AccessError < ErrorUsage
      def initialize(remote_repo,access_rights=nil)
        super(error_msg(remote_repo,access_rights))
      end
     private
      def error_msg(remote_repo,access_rights=nil)
        if access_rights
          "#{access_rights.pp_form()} access rights denied to remote repo #{remote_repo}"
        else
        "Access denied to remote repo #{remote_repo}"
        end
      end
    end
    class AccessRights
      class R < self
        def self.remote_repo_form()
          "R"
        end
        def self.pp_form()
          "Read"
        end
      end
      class RW < self
        def self.remote_repo_form()
          "RW+"
        end
         def self.pp_form()
          "Read/Write"
        end
      end
      def self.convert_from_string_form(rights)
        case rights
          when "r" then R
          when "rw" then RW
          else raise ErrorUsage("Illegal access rights string '#{rights}'")
        end  
      end
    end
  end
end; end
