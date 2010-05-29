module XYZ
  class ProjectController < Controller
    def create(name)
      c = ret_session_context_id()
      Project.create(name,c)
      "project created with name #{name}"
    end
  end
end
