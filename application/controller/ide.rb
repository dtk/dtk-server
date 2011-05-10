module XYZ
  class IdeController < Controller

    def index()
      c = ret_session_context_id()
      model_handle = ModelHandle.new(c,:project)
      projects = Project.get_all(model_handle)
      pp [:projects,projects]

      projects.each_with_index { |p,i|
        projects[i][:tree] = p.get_target_tree()
        projects[i][:name] = projects[i][:display_name]
      }
pp projects

      projects_json = JSON.generate(projects)
      run_javascript("R8.IDE.init(#{projects_json});")

      tpl = R8Tpl::TemplateR8.new("ide/test_tree",user_context())
      run_javascript("R8.IDE.testTree();")
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
