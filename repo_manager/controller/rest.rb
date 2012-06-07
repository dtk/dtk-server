class RestController < Controller
  helper :rest
  engine :none
  provide(:html, :type => 'text/html'){|a,s|s.to_json} 
  provide(:json, :type => 'application/json'){|a,s|s.to_json}

  include R8::RepoManager
  def index
    rest_ok_response :version => "0.1"
  end

  def get_file_content(repo_name,path)
    content = GitoliteManager::Repo.new(repo_name).file_content(path)
    rest_ok_response :content => content
  end
end
