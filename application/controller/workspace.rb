module XYZ
  class WorkspaceController < Controller
    #have default template/layout set for workspace controller calls
    #probably only used typically for index call
    layout :workspace

    def index
      print "reached from /xyz/workspace\n"
    end
  end
end
