module R8::RepoManager; class GitRepo
  class FileAccess < self
    def add_file(file_rel_path,content)
      content ||= String.new
      file_path = qualified_path(file_rel_path)
      chdir_and_checkout do
        File.open(file_path,"w"){|f|f << content}
        git_command(:add,file_path)
      end
    end

    def remove_file(file_rel_path)
      file_path = qualified_path(file_rel_path)
      chdir_and_checkout do
        git_command(:rm,file_path)
      end
    end
    
    def commit(commit_msg)
      #TODO is chdir_and_checkout needed
      chdir_and_checkout do
        @grit_repo.commit_index(commit_msg)
      end
    end

   private
     def qualified_path(file_rel_path)
       "#{@repo_dir}/#{file_rel_path}"
     end

     def chdir_and_checkout(branch=nil,&block)
       branch ||= @branch
       Dir.chdir(@repo_dir) do 
         current_head = @grit_repo.head.name
         git_command(:checkout,branch) unless current_head == branch
         return unless block
         yield
         unless current_head == branch
           git_command(:checkout,current_head)
         end
       end
     end
   end
end;end

