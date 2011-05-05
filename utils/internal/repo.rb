require 'grit'
module XYZ
  class Repo 
    def self.get_file_content(file_asset,repo_path)
      repo = get_repo(file_asset)
      ret = nil
      repo.checkout(repo_path) do
        full_path = "#{repo.path}/#{file_asset[:path]}"
        ret = File.open(full_path){|f|f.read}
      end
      ret
    end

    def checkout(branch_name,&block)
      branch_name ||= "master"
      @index.read_tree(branch_name)
      #TODO: when get index mechanisms to work dont need below
      current_head = @grit_repo.head.name
      git_command.checkout({},branch_name)
      return unless block
      yield
      unless current_head == branch_name
        git_command.checkout({},current_head)
      end
    end

    attr_reader :path
   private
    attr_reader :grit_repo
    def initialize(path)
      @path = path
      @grit_repo = Grit::Repo.new(path)
      @index = @grit_repo.index #creates new object so use @index, not grit_repo
    end
    #TODO stubbed; should use context info in file asset id_handle to determine which repo to use
    def self.get_repo(file_asset)
      CachedRepo
    end
    CachedRepo = self.new(R8::EnvironmentConfig::CoreCookbooksRoot)
 
    def add_branch(branch_name,start="master")
      start ||= "master"
      checkout(start)
      @index.commit("Adding branch #{branch_name}", [@grit_repo.commit(start)], nil, nil, branch_name)
    end

    def add_file(file_name,content,branch_name="master")
      message = "Adding #{file_name} to #{branch_name}"
      ret = nil
      Dir.chdir(@path) do
        File.open(file_name,"w"){|f|f << content}
        checkout(branch_name) do 
          @grit_repo.add(file_name)
          ret = @grit_repo.commit_index(message)
        end
      end  

      #TODO: new form not working
      # @index.add(file_name,content)
      # @ index.commit(message, [@grit_repo.commit(branch_name)])
      ret
    end

    def branch_exists?(branch_name)
      @grit_repo.heads.find{|h|h.name == branch_name} ? true : nil
    end

    def git_command()
      @grit_repo.git
    end
  end
end
=begin
TODO: remove when finsihing testing
require 'rubygems'
require 'pp'
file_name = ARGV[0]
branch_name = ARGV[1]
branch_start = ARGV[2]
r = XYZ::Repo.new("/root/Repo")
r.add_branch(branch_name,branch_start) unless r.branch_exists?(branch_name)
pp r.add_file(file_name,"initial text",branch_name)
=end

