require 'rubygems'
require 'pp'
require 'grit'
module XYZ
  class Repo < Grit::Repo
    def initialize(path)
      super(path)
      @cached_index = self.index
    end

    def checkout_branch(branch_name)
      i.read_tree(branch_name)
    end

    def add_branch(branch_name)
      i.read_tree(branch_name)
      i.commit("Adding branch #{branch_name}", [commits.first], nil, nil, branch_name)
    end

    def add_file_to_master(file_name,content)
      i.read_tree("master")
      i.add(file_name,content)
      i.commit("Adding #{file_name} to master", [commits.first])
    end


    def add_file_to_branch(branch_name,file_name,content)
      i.add(file_name,content)
 #     i.commit("Adding #{file_name} to branch #{branch_name}", [commit(branch_name)], nil, nil, branch_name)
    end

    def i()
      @cached_index
    end
  end
end
def add_multiple_commits_same_file_different_content2(repo)
  Dir.chdir("/root/Repo") do
    previous_commit = repo.commits.first && repo.commits.first.id
    dir = ""
    (0...5).each do |count|
      i1 = repo.i
      i1.read_tree('master')
      i1.add("#{dir}foo.txt", "hello foo, count is #{count}.\n")
      dir += "sd#{count}/"
      previous_commit =  i1.commit("my commit - #{count}",
                             previous_commit,
                                 Grit::Actor.new("j#{count}", "e@e#{count}.zz"),
                             previous_commit.nil? ? nil : repo.commits(previous_commit).first.tree)
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
      content = "hello new foo, count is #{count}.\n"
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
add_multiple_commits_same_file_different_content(r)

=begin
index = r.i
index.add('myfile.txt', 'This is the content')
index.commit('first commit')

index.add('myfile2.txt', 'This is the content2')
index.commit('2nd commit')
=end
#r.checkout_branch("b1")
#r.add_file_to_branch("b1","foo2.text","sample text")
#r.add_file_to_master("foo3.text","foo3 text")
#pp r.commit_all("foo3")
