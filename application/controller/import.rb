
require 'fileutils'

module XYZ
  class ImportController < AuthController

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

      #TODO: module_name; this is hack to get it from tar.gz file name
      module_name = pkg_filename.gsub(/\.tar\.gz$/,"")
      prefixes_to_strip = %w{puppetlabs ghoneycutt} #TODO: complate hack
      prefixes_to_strip.each{|pre|module_name.gsub!(Regexp.new("^#{pre}-"),"")}
      module_name.gsub!(/-[0-9]+\.[0-9]+\.[0-9]+$/,"")

      #mv the tmp file to under CompressedFileStore
      tmp_path = tmp_file_handle.path
      tmp_file_handle.close
      compressed_file = "#{R8::EnvironmentConfig::CompressedFileStore}/#{pkg_filename}"
      FileUtils.mv tmp_path, compressed_file

      config_agent_type = :puppet
      library_idh = Library.get_users_private_library(model_handle(:library)).id_handle()
      raise Error.new("TODO: fix up: Implementation.create_library_repo_and_implementation has been removed")
      repo_obj,impl_obj = Implementation.create_library_repo_and_implementation(library_idh,module_name,config_agent_type, :delete_if_exists => true)

      repo_name = repo_obj[:repo_name]
      module_dir = repo_obj[:local_dir]
      base_dir = repo_obj[:base_dir]
    
#EXTRACT AND PARSE CODE-----------------------------
      user_obj = CurrentSession.new.get_user_object()
      username = user_obj[:username]
      repo_name =  "#{username}-#{config_agent_type}-#{module_name}"

      opts = {:strip_prefix_count => 1} 
      base_dir = R8::Config[:repo][:base_directory]

      #begin capture here so can rerun even after loading in dir already
      begin
        #extract tar.gz file into directory
        Extract.single_module_into_directory(compressed_file,repo_name,base_dir,opts)
      rescue Exception => e
        #raise e
      end
      
      opts = {:strip_prefix_count => 1} 
      #begin capture here so can rerun even after loading in dir already
      begin
        #extract tar.gz file into directory
        Extract.single_module_into_directory(compressed_file,repo_name,base_dir,opts)
      rescue Exception => e
        #raise e
      end

      impl_obj.create_file_assets_from_dir_els()

      #parsing
      begin
        raise Error.new("ConfigAgent.parse_given_module_directory(config_agent_type,module_dir) needs to be converted to form ConfigAgent.parse_given_module_directory(config_agent_type,impl_obj")
        r8_parse = ConfigAgent.parse_given_module_directory(config_agent_type,module_dir)
       rescue ErrorUsage::Parsing => error
        return {
          :data=> {:errors=>error} #TODO: must be changed
        }
#TODO: deprecated this  rescue R8ParseError => e
       rescue => e
        pp [:r8_parse_error, e.to_s]
        return {
          :data=> {:errors=>{:type=>"parse",:error=>e.to_s}}
        }
      end

      meta_generator = GenerateDSL.create()
      refinement_hash = meta_generator.generate_refinement_hash(r8_parse,module_name,impl_obj.id_handle)
      return {
        :data=> refinement_hash
      }

      #pp refinement_hash

        #in between here refinement has would have through user interaction the user set the needed unknowns
        #mock_user_updates_hash!(refinement_hash)
      r8meta_hash = refinement_hash.render_hash_form()
      #TODO: currently version not handled
      r8meta_hash.delete("version")
      r8meta_path = "#{module_dir}/r8meta.#{config_agent_type}.yml"
      r8meta_hash.write_yaml(STDOUT)
      File.open(r8meta_path,"w"){|f|r8meta_hash.write_yaml(f)}
      
      pp r8meta_hash
      return {
        :data=> r8meta_hash
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
      meta_info_hash = JSON.parse(request.params["import_def"])
      pp meta_info_hash
      ComponentDSL::GenerateFromImpl.save_dsl_info(meta_info_hash,model_handle(:implementation))
      {:data => ''}
    end
  end
end
