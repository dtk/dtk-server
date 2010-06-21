module XYZ
  class WorkspaceController < Controller
    #have default template/layout set for workspace controller calls
    #probably only used typically for index call
    layout :workspace

    def index
      print "reached from /workspace\n"
    end

    def list
        "this is the it, getting here?????"
    end

    #This function will be called after the workspace framework is loaded,
    #probably as part of an action set
    def loadtoolbar
=begin
      toolbar_items = workspace.get_toolbar_items
      layout :workspace__toolbar_items
      assign(@toolbar_items,toolbar_items)
      render 'toolbar_items'

      #build in roles/permission checks here to filter the list
=end
    end

    def testsearch
      "hello there, inside of testsearch"
    end

  end
end
