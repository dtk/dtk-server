class RestController < Controller
  helper :rest
  engine :none
  provide(:html, :type => 'text/html'){|a,s|s.to_json} 
  provide(:json, :type => 'application/json'){|a,s|s.to_json}

  include DTK::RepoManager
  def index
    rest_ok_response :version => "0.1"
  end

  class AdminController < self
    map "/rest/admin"

    def add_user()
      username,rsa_pub_key = ret_non_null_request_params(:username,:rsa_pub_key)
      noop_if_exists,delete_if_exists = ret_request_params(:noop_if_exists,:delete_if_exists)
      opts = Hash.new
      opts.merge!(:noop_if_exists => true) if  noop_if_exists
      opts.merge!(:delete_if_exists => true) if  delete_if_exists

      Admin.add_user(username,rsa_pub_key,opts)
      rest_ok_response :usename => username
    end

    def delete_user()
      username = ret_non_null_request_params(:username)
      Admin.delete_user(username)
      rest_ok_response :usename => username
    end

    def create_repo()
      repo_name,username = ret_non_null_request_params(:repo_name,:username)
      access_rights = ret_request_params(:access_rights) || "R" 
      repo_user_acls = Admin.ret_repo_user_acls(username,access_rights)
      repo_created = Admin.create_repo(repo_name,repo_user_acls,:noop_if_exists => true)
      unless repo_created
        Log.info("repo (#{repo_name}) created already")
      end
      rest_ok_response
    end

    def set_user_rights_in_repo()
      repo_name,username = ret_non_null_request_params(:repo_name,:username)
      access_rights = ret_request_params(:access_rights) || "R" 
      Admin.set_user_rights_in_repo(username,repo_name,access_rights)
      rest_ok_response :repo_name => repo_name
    end

    def list_repos()
      repos = Admin.list_repos()
      rest_ok_response :repos => repos
    end

    def delete_repo()
      repo_name = ret_non_null_request_params(:repo_name)
      Admin.delete_repo(repo_name)
      rest_ok_response :repo_name => repo_name
    end

    def server_dtk_username()
      rest_ok_response :dtk_username => Admin.dtk_username()
    end

    def server_ssh_rsa_pub_key()
      rest_ok_response :rsa_pub_key => Admin.get_ssh_rsa_pub_key()
    end

    def update_ssh_known_hosts()
      remote_host = ret_non_null_request_params(:remote_host)
      Admin.update_ssh_known_hosts(remote_host)
    end
  end

  class RepoController < self
    map "/rest/repo"
    def get_file_content()
      repo_name,path = ret_non_null_request_params(:repo_name,:path)
      branch = ret_request_params(:branch)||'master'
      content = Repo.new(repo_name,branch).file_content(path)
      rest_ok_response :content => content
    end

    def update_file_content()
      repo_name,path,content = ret_non_null_request_params(:repo_name,:path,:content)
      branch = ret_request_params(:branch)||'master'
      Repo.new(repo_name,branch).update_file_and_commit(path,content)
      rest_ok_response
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
    
    def push_to_mirror()
      repo_name,mirror_host = ret_non_null_request_params(:repo_name,:mirror_host)
      Repo.new(repo_name).push_to_mirror(mirror_host)
      rest_ok_response
    end
  end

  def error
    exception = request.env["rack.route_exceptions.exception"]
pp [:error, exception,exception.backtrace[0..15]]
    rest_notok_response ::DTK::RestError.create(exception).hash_form()
  end
end
