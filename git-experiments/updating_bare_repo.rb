require 'rubygems'
require 'grit'
repo_name = '/tmp/repo.git'
repo = Grit::Repo.init_bare(repo_name)
index = Grit::Index.new(repo)
index.add('mytext.txt', "This is my first text")
index.commit('Text commit')

index = repo.index
index.read_tree('master')
index.add('mytext.txt', "This is my second text")
index.commit('Text commit',[repo.commits.first])
