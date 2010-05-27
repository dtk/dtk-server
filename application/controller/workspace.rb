module XYZ
  class WorkspaceController < Controller
    #have default template/layout set for workspace controller calls
    #probably only used typically for index call
    layout :workspace

    #TODO: load the workspace
    #path to reach this is /xyz/workspace
    def index
      print "reached from /xyz/workspace\n"
      #TBD: move so only instantiated once
      @public_js_root = R8::Config[:public_js_root]
      @public_css_root = R8::Config[:public_css_root]
      @public_images_root = R8::Config[:public_images_root]
    end
  end
end
