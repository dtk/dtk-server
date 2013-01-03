module DTK; class Repo 
  class Remote
    class AccessRights
      class R < self
        def self.remote_repo_form()
          "R"
        end
      end
      class RW < self
        def self.remote_repo_form()
          "RW+"
        end
      end
    end
  end
end; end
