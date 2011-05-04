require 'rubygems'
require 'pp'
require 'grit'
module XYZ
  class Repo 
    def initialize(path)
      @path = path
      @grit_repo = Grit::Repo.new(path)
      @index = @grit_repo.index #creates new object so use @index, not grit_repo
    end

    def add_branch(branch_name)
      
      @index.read_tree("master")
      @index.commit("Adding branch #{branch_name}", [@grit_repo.commits.first], nil, nil, branch_name)
    end

    def checkout_branch(branch_name)
       @index.read_tree(branch_name)
    end

    def checkout_master()
       @index.read_tree("master")
    end

    def add_file_to_master(file_name,content)
      checkout_master()
      message = "Adding #{file_name} to master"
      Dir.chdir(@path) do
        File.open(file_name,"w"){|f|f << content}
        @grit_repo.add(file_name)
        @grit_repo.commit_index(message)
      end  

      #TODO: new form not working
      # @index.add(file_name,content)
      # @ index.commit("Adding #{file_name} to master", [@grit_repo.commits.first])
    end


    def add_file_to_branch(branch_name,file_name,content)
      @index.add(file_name,content)
 #     @index.commit("Adding #{file_name} to branch #{branch_name}", [commit(branch_name)], nil, nil, branch_name)
    end
   private
    def git()
      @grit_repo.git
    end
  end
end

def add_multiple_commits_same_file_different_content(repo)
  Dir.chdir("/root/Repo") do
    previous_commit = repo.commits.first && repo.commits.first.id
    (0...5).each do |count|
      i1 = repo.i
      i1.read_tree('master')
      file_name = "foo#{count.to_s}.txt"
      content = "hello new foo2, count is #{count}.\n"
      File.open(file_name,"w"){|f|f << content}
      repo.add(file_name)
      repo.commit_index("my commit - #{count}")
=begin      
     i1.add("foo#{count.to_s}.txt", "hello foo, count is #{count}.\n")
      previous_commit =  i1.commit("my commit - #{count}",
                             previous_commit,
                                 Grit::Actor.new("j#{count}", "e@e#{count}.zz"),
                             previous_commit.nil? ? nil : repo.commits(previous_commit).first.tree)
=end
    end
  end
end

r = XYZ::Repo.new("/root/Repo")
r.add_file_to_master("hij.txt","new")
=begin
#add_multiple_commits_same_file_different_content(r)


index = r.i
#index.add('myfile2.txt', 'This is the content')
Dir.chdir("/root/Repo") do
  file_name = 'myfile2.txt'
  content = "hello new foo5\n"
#  File.open(file_name,"w"){|f|f << content}
  index.read_tree("master")
  index.add(file_name,content)
  index.commit('commit x',[r.commits.first])
end


index.add('myfile2.txt', 'This is the content2')
index.commit('2nd commit')

#r.checkout_branch("b1")
#r.add_file_to_branch("b1","foo2.text","sample text")
#r.add_file_to_master("foo3.text","foo3 text")
#pp r.commit_all("foo3")
=end
