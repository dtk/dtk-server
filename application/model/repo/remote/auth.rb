module DTK; class Repo 
  class Remote
    class AccessRights
      class R < self
        def self.remote_repo_form()
          "r"
        end
      end
      class RW < self
        def self.remote_repo_form()
          "rw+"
        end
      end
    end
  end
end; end
