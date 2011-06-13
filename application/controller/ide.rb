module XYZ
  class IdeController < Controller

    def index()
      c = ret_session_context_id()
      model_handle = ModelHandle.new(c,:project)
      projects = Project.get_all(model_handle)
      pp [:projects,projects]

      projects.each_with_index { |p,i|
        projects[i][:tree] = {}
        projects[i][:tree][:targets] = p.get_target_tree()
        projects[i][:tree][:component_templates] = p.get_implementaton_tree(:include_file_assets => true)
        projects[i][:name] = projects[i][:display_name]
      }
#pp projects
      tpl = R8Tpl::TemplateR8.new("ide/project_tree_leaf",user_context())
      tpl.set_js_tpl_name("project_tree_leaf")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("ide/panel_frame",user_context())
      tpl.set_js_tpl_name("ide_panel_frame")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

#==========================
#Include target specific js that will be needed
#TODO: move out of here eventually
      tpl_info_hash = Hash.new

      tpl = R8Tpl::TemplateR8.new("node_group/wspace_display",user_context())
      tpl.set_js_tpl_name("ng_wspace_display")
      tpl_info_hash[:node_group] = tpl.render()
      include_js_tpl(tpl_info_hash[:node_group][:src])

      tpl = R8Tpl::TemplateR8.new("node/wspace_display",user_context())
      tpl.set_js_tpl_name("node_wspace_display")
      tpl_info_hash[:node] = tpl.render()
      include_js_tpl(tpl_info_hash[:node][:src])

      tpl = R8Tpl::TemplateR8.new("datacenter/wspace_monitor_display",user_context())
      tpl.set_js_tpl_name("wspace_monitor_display")
      tpl_info_hash[:monitor] = tpl.render()
      include_js_tpl(tpl_info_hash[:monitor][:src])
#==========================

      projects_json = JSON.generate(projects)
#TODO: figure out why this user init isnt firing inside of bundle and return
#DEBUG
      run_javascript("R8.User.init();")
      run_javascript("R8.IDE.init(#{projects_json});")
#      run_javascript("R8.IDE.addProjects(#{projects_json});")

#      tpl = R8Tpl::TemplateR8.new("ide/test_tree2",user_context())
#      run_javascript("R8.IDE.testTree();")

      return {:content=>tpl.render(),:panel=>'project_panel'}

#      return {:content=>''}
    end


    def test_tree()
#      tpl = R8Tpl::TemplateR8.new("ide/test_tree",user_context())

      run_javascript("R8.IDE.init();")
      run_javascript("R8.IDE.testTree();")
#      return {:content=>tpl.render(),:panel=>'editor-panel'}
      return {:content=>'this is garb!!!!',:panel=>'editor-panel'}
    end
  end

end
