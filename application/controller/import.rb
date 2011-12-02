
require 'fileutils'

module XYZ
  class ImportController < Controller

    def index
      return {:data=>''}
    end

    def load_wizard()
      tpl = R8Tpl::TemplateR8.new("ide/panel",user_context())
      tpl.set_js_tpl_name("workspace_panel")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("import/step_one",user_context())
      tpl.set_js_tpl_name("import_step_one")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("import/step_two",user_context())
      tpl.set_js_tpl_name("import_step_two")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("import/step_three",user_context())
      tpl.set_js_tpl_name("import_step_three")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("import/step_four",user_context())
      tpl.set_js_tpl_name("import_step_four")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("import/step_five",user_context())
      tpl.set_js_tpl_name("import_step_five")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("import/display_attribute",user_context())
      tpl.set_js_tpl_name("import_display_attribute")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      tpl = R8Tpl::TemplateR8.new("import/edit_attribute",user_context())
      tpl.set_js_tpl_name("import_edit_attribute")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

#      run_javascript("R8.User.init();")
#      run_javascript("R8.Import.init(#{import_json},2);")
      run_javascript("R8.Import.loadWizard();")

      return {:content=>''}
    end

    def step_one()
      module_upload = request.params["module_package"]
      pkg_filename = module_upload[:filename]
      tmp_file_handle = module_upload[:tempfile]

      #mv the tmp file to under CompressedFileStore
      tmp_path = tmp_file_handle.path
      tmp_file_handle.close
      compressed_file = "#{R8::EnvironmentConfig::CompressedFileStore}/#{pkg_filename}"
      FileUtils.mv tmp_path, compressed_file
    
#EXTRACT AND PARSE CODE-----------------------------
      module_name = pkg_filename.gsub(/\.tar\.gz$/,"")
      #TODO: temp hack to get module_name until parse module file
      if module_name =~ /-(.+)-[0-9]+\.[0-9]+\.[0-9]$/
        module_name = $1
      end
      config_agent_type = :puppet
      user_obj = CurrentSession.new.get_user_object()
      username = user_obj[:username]
      repo_name =  "#{username}-#{config_agent_type}-#{module_name}"

      opts = {:strip_prefix_count => 1} 
      base_dir = R8::EnvironmentConfig::ImportTestBaseDir

      #begin capture here so can rerun even after loading in dir already
      begin
        #extract tar.gz file into directory
        Extract.single_module_into_directory(compressed_file,repo_name,base_dir,opts)
      rescue Exception => e
        #raise e
      end
      
      module_dir = "#{base_dir}/#{repo_name}"
      user_group = user_obj.get_private_group()
      user_group_id = user_group && user_group[:id]
      top_container_idh = top_id_handle(:group_id => user_group_id)
      library_idh,impl_idh = Model.add_library_files_from_directory(top_container_idh,module_dir,module_name,config_agent_type)
      #parsing
      begin
        r8_parse = ConfigAgent.parse_given_module_directory(config_agent_type,module_dir)
       rescue ConfigAgent::ParseErrors => errors
        errors.set_file_asset_ids!(model_handle)
        pp [:puppet_error,errors.error_list.map{|e|e.to_s}]
        return {:data => {:errors=>errors.error_list}}
       rescue R8ParseError => e
        pp [:r8_parse_error, e.to_s]
        return {:data => {:errors=>errors.error_list}}
      end

      meta_generator = GenerateMeta.create("1.0")
      refinement_hash = meta_generator.generate_refinement_hash(r8_parse,module_name)
      #pp refinement_hash
        
        #in between here refinement has would have through user interaction the user set the needed unknowns
        #mock_user_updates_hash!(refinement_hash)
      r8meta_hash = refinement_hash.render_hash_form()
      pp r8meta_hash
      return {
        :data=> {
          :import_def=>r8meta_hash
        }
      }
=begin
Not reached
      return {
        :data=> {
          :import_id=>pkg_root
        }
      }
=end
    end

    def step_two(id)
      files = {
        "1" => 'hadoop.rb',
        "2" => 'gearman.rb',
      }
      file_path = R8::Config[:puppet_test_import_path]+'/'+files[id]

      if File.exists?(file_path)
        import_content = eval(IO.read(file_path))
        import_json = JSON.generate(import_content)

        tpl = R8Tpl::TemplateR8.new("ide/panel",user_context())
        tpl.set_js_tpl_name("workspace_panel")
        tpl_info = tpl.render()
        include_js_tpl(tpl_info[:src])

        tpl = R8Tpl::TemplateR8.new("import/step_two",user_context())
        tpl.set_js_tpl_name("import_step_two")
        tpl_info = tpl.render()
        include_js_tpl(tpl_info[:src])

        tpl = R8Tpl::TemplateR8.new("import/step_three",user_context())
        tpl.set_js_tpl_name("import_step_three")
        tpl_info = tpl.render()
        include_js_tpl(tpl_info[:src])

        tpl = R8Tpl::TemplateR8.new("import/step_four",user_context())
        tpl.set_js_tpl_name("import_step_four")
        tpl_info = tpl.render()
        include_js_tpl(tpl_info[:src])

        tpl = R8Tpl::TemplateR8.new("import/display_attribute",user_context())
        tpl.set_js_tpl_name("import_display_attribute")
        tpl_info = tpl.render()
        include_js_tpl(tpl_info[:src])

        tpl = R8Tpl::TemplateR8.new("import/edit_attribute",user_context())
        tpl.set_js_tpl_name("import_edit_attribute")
        tpl_info = tpl.render()
        include_js_tpl(tpl_info[:src])

        run_javascript("R8.User.init();")
        run_javascript("R8.Import.init(#{import_json},2);")

        return {:content=>''}
      end

      return {:data => ''}
    end

    def finish()
      import_def = JSON.parse(request.params["import_def"])
pp import_def
    end
  end
end
