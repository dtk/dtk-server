class RestController < Controller
  helper :rest
  engine :none
  provide(:html, :type => 'text/html'){|a,s|s.to_json} 
  provide(:json, :type => 'application/json'){|a,s|s.to_json}

  include R8::RepoManager
  def index
    rest_ok_response :version => "0.1"
  end

  class AdminController < self
    map "/rest/admin"

    def add_user()
      username,rsa_pub_key = ret_non_null_request_params(:username,:rsa_pub_key)
      GitoliteManager::Repo::Admin.add_user(username,rsa_pub_key)
      rest_ok_response :usename => username
    end

    def delete_user()
      username = ret_non_null_request_params(:username)
      GitoliteManager::Repo::Admin.delete_user(username)
      rest_ok_response :usename => username
    end

    def create_repo_and_user()
      repo_name,username,rsa_pub_key = ret_non_null_request_params(:repo_name,:username,:rsa_pub_key)
      GitoliteManager::Repo::Admin.create_repo_and_user(repo_name,username,rsa_pub_key,"RW+")
      rest_ok_response :repo_name => repo_name
    end
  end

  class RepoController < self
    map "/rest/repo"
    def get_file_content(repo_name,path)
      content = GitoliteManager::Repo.new(repo_name).file_content(path)
      rest_ok_response :content => content
    end
  end

  def error
    exception = request.env["rack.route_exceptions.exception"]
    rest_notok_response XYZ::RestError.create(exception).hash_form()
  end
end
