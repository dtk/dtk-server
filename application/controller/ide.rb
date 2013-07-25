module XYZ
  class IdeController < Controller

    def index()
      projects = Project.get_all(model_handle(:project))
      pp [:projects,projects]

      projects.each_with_index { |p,i|
        projects[i][:tree] = {}
        projects[i][:tree][:targets] = p.get_target_tree()
        projects[i][:tree][:implementations] = p.get_module_tree(:include_file_assets => true)
        projects[i][:name] = projects[i][:display_name]
      }
      tpl = R8Tpl::TemplateR8.new("ide/project_tree_leaf",user_context())
      tpl.set_js_tpl_name("project_tree_leaf")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("ide/l_panel",user_context())
      tpl.set_js_tpl_name("l_panel")
#      tpl = R8Tpl::TemplateR8.new("ide/panel_frame",user_context())
#      tpl.set_js_tpl_name("ide_panel_frame")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("ide/editor_panel",user_context())
      tpl.set_js_tpl_name("editor_panel")
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

      tpl = R8Tpl::TemplateR8.new("node/wspace_display_ide",user_context())
      tpl.set_js_tpl_name("node_wspace_display_ide")
      tpl_info_hash[:node] = tpl.render()
      include_js_tpl(tpl_info_hash[:node][:src])

      tpl = R8Tpl::TemplateR8.new("datacenter/wspace_monitor_display",user_context())
      tpl.set_js_tpl_name("wspace_monitor_display")
      tpl_info_hash[:monitor] = tpl.render()
      include_js_tpl(tpl_info_hash[:monitor][:src])

      tpl = R8Tpl::TemplateR8.new("workspace/notification_list_ide",user_context())
      tpl.set_js_tpl_name("notification_list_ide")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("component/library_search",user_context())
      tpl.set_js_tpl_name("component_library_search")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("node/library_search",user_context())
      tpl.set_js_tpl_name("node_library_search")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("assembly/library_search",user_context())
      tpl.set_js_tpl_name("assembly_library_search")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])
#==========================

#      include_js('plugins/search.cmdhandler2')
      include_js('plugins/r8.cmdbar.assemblies')
      include_js('plugins/r8.cmdbar.components')
      include_js('plugins/r8.cmdbar.nodes')
      include_js('plugins/r8.cmdbar.tasks')

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

    def new_project()
      tpl = R8Tpl::TemplateR8.new("ide/new_project",user_context())
      tpl.assign(:_app,app_common())
#      tpl.assign(:required_attr_list,required_attr_list)

      targets = Array.new
      targets = [{
        :id => '234sadf',
        :name => 'AWS 1 - East Region'
      },
      {
        :id => '234sadf',
        :name => 'AWS 1 - West Region'
      },
      {
        :id => '234sadf',
        :name => 'AWS 1 - EU West Region'
      },
      {
        :id => '234sadf',
        :name => 'AWS 1 - Asia (Singapore) Region'
      },
      {
        :id => '234sadf',
        :name => 'AWS 1 - Asia (Japan) Region'
      }
      ]
      tpl.assign(:targets,targets)

      panel_id = request.params['panel_id']

      include_js('plugins/create_project.tool')

      run_javascript("R8.CreateProjectTool.init();")
#      run_javascript("R8.IDE.initCreateProject();")
#      run_javascript("R8.CommitTool2.renderTree(#{commit_tree_json},'edit','change-list-tab-content');")

      return {
        :content=> tpl.render(),
        :panel=>panel_id
      }
    end

    def new_target()
      tpl = R8Tpl::TemplateR8.new("ide/new_target",user_context())
      tpl.assign(:_app,app_common())
#      tpl.assign(:required_attr_list,required_attr_list)

      targets = Array.new
      targets = [{
        :id => '234sadf',
        :name => 'AWS 1 - East Region'
      },
      {
        :id => '234sadf',
        :name => 'AWS 1 - West Region'
      },
      {
        :id => '234sadf',
        :name => 'AWS 1 - EU West Region'
      },
      {
        :id => '234sadf',
        :name => 'AWS 1 - Asia (Singapore) Region'
      },
      {
        :id => '234sadf',
        :name => 'AWS 1 - Asia (Japan) Region'
      }
      ]
      tpl.assign(:targets,targets)

      panel_id = request.params['panel_id']

      include_js('plugins/create_target.tool')

      run_javascript("R8.CreateTargetTool.init();")
#      run_javascript("R8.IDE.initCreateProject();")
#      run_javascript("R8.CommitTool2.renderTree(#{commit_tree_json},'edit','change-list-tab-content');")

      return {
        :content=> tpl.render(),
        :panel=>panel_id
      }
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
