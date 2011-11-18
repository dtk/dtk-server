#TODO: incomplete; when refactored to use adapter structure; structure looked like mock used all same as grit except for clone branch
module XYZ
  class RepoMock < Repo
    def clone_branch(context,new_branch)
      nil
    end
  end
end
