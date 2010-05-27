module XYZ
  class WorkspaceController < Controller
    #have default template/layout set for workspace controller calls
    #probably only used typically for index call
    layout :workspace

    def index
      print "reached from /xyz/workspace\n"
    end

    #This function will be called after the workspace framework is loaded,
    #probably as part of an action set
    def loadtoolbar
=begin
      toolbar_items = R8.Workspace.get_toolbar_items
      R8.Template.set_view('workspace/toolbar_items')
      R8.Template.assign(@toolbar_items,toolbar_items)
      R8.Template.render('toolbar_items')

      R8.Template.set_view('workspace/main_toolbar')
      R8.Template.render()
      #build in roles/permission checks here to filter the list
=end
    end
  end
end
