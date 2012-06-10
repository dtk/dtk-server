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
      Admin.add_user(username,rsa_pub_key)
      rest_ok_response :usename => username
    end

    def delete_user()
      username = ret_non_null_request_params(:username)
      Admin.delete_user(username)
      rest_ok_response :usename => username
    end

    def add_user_to_repo()
      repo_name,username = ret_non_null_request_params(:repo_name,:username)
      access_rights = "RW+" #TODO: make this a settable param
      Admin.add_user_to_repo(repo_name,username,rsa_pub_key,access_rights)
      rest_ok_response :repo_name => repo_name
    end
  end

  class RepoController < self
    map "/rest/repo"
    def get_file_content(repo_name,path)
      content = Repo.new(repo_name).file_content(path)
      rest_ok_response :content => content
    end

    def list_recursive(repo_name)
      paths = Repo.new(repo_name).ls_r()
      rest_ok_response :paths => paths
    end

    def branches(repo_name)
      branches = Repo.new(repo_name).branches()
      rest_ok_response :branches => branches
    end

    def create_branch()
      repo_name,new_branch = ret_non_null_request_params(:repo_name,:new_branch)
      Repo.new(repo_name).create_branch(new_branch)
      rest_ok_response :branch => new_branch
    end
  end

  def error
    exception = request.env["rack.route_exceptions.exception"]
    rest_notok_response XYZ::RestError.create(exception).hash_form()
  end
end
