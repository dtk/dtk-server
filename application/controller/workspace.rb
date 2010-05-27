module XYZ
  class WorkspaceController < Controller
    #have default template/layout set for workspace controller calls
    #probably only used typically for index call
    layout :workspace

    #TODO: load the workspace
    #path to reach this is /xyz/workspace
    def index
    print "reached from /xyz/workspace\n"
    end
  end
end
