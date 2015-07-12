module DTK; class Repo
  class Remote
    module AuthMixin
      ACCESS_READ  = 'R'
      ACCESS_WRITE = 'W'

      # TODO: ModuleBranch::Location: see why need client_rsa_pub_key
      def authorize_dtk_instance(client_rsa_pub_key = nil, access_rights = nil)
        username     = dtk_instance_remote_repo_username()
        rsa_pub_key  = dtk_instance_rsa_pub_key()
        rsa_key_name = dtk_instance_remote_repo_key_name()
        access_rights ||= ACCESS_READ

        authorize_user(username, rsa_pub_key, rsa_key_name, access_rights, remote.module_name, remote.namespace, remote.module_type, client_rsa_pub_key)
      end

      def authorize_end_user(mh, module_name, module_namespace, type, rsa_pub_key, access_rights)
        username = get_end_user_remote_repo_username(mh, rsa_pub_key)
        authorize_user(username, rsa_pub_key, access_rights.remote_repo_form(), module_name, module_namespace, type)
      end

      private

      def authorize_user(username, _rsa_pub_key, _rsa_key_name, access_rights, module_name, module_namespace, type, client_rsa_pub_key = nil)
        grant_user_rights_params = {
          name: module_name,
          namespace: module_namespace || DefaultsNamespace,
          type: type_for_remote_module(type),
          username: username,
          access_rights: access_rights
        }
        # TODO: [Haris] We do want to keep API same until repo client since we need to support two clients
        client.grant_user_access_to_module(grant_user_rights_params, client_rsa_pub_key)
      end

      # matches namespace from the name remote_repo e.g. "dtk"
      def get_namespace(remote_repo_name)
        if remote_repo_name
          remote_repo_name.scan(/\A.*?(?=--)/).first
        end
      end
    end

    class AccessError < ErrorUsage
      def initialize(remote_repo, access_rights = nil)
        super(error_msg(remote_repo, access_rights))
      end

      private

      def error_msg(remote_repo, access_rights = nil)
        if access_rights
          "#{access_rights.pp_form()} access rights denied to remote repo #{remote_repo}"
        else
        "Access denied to remote repo #{remote_repo}"
        end
      end
    end
    class AccessRights
      class R < self
        def self.remote_repo_form
          'R'
        end
        def self.pp_form
          'Read'
        end
      end
      class RW < self
        def self.remote_repo_form
          'RW+'
        end
         def self.pp_form
          'Read/Write'
        end
      end
      def self.convert_from_string_form(rights)
        case rights
          when 'r' then R
          when 'rw' then RW
          else fail ErrorUsage("Illegal access rights string '#{rights}'")
        end
      end
    end
  end
end; end
