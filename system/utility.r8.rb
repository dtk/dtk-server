module R8Tpl
  module Utility
    module I18n
      def add_i18n_strings_to_rendered_tasks!(task,i18n={})
        model_name = task[:level] && task[:level].to_sym
        if model_info = I18nMappingInfo[model_name]
          model_info[:models].each{|m|i18n[m] ||= get_model_i18n(m)}
          source = task[model_info[:name_field]]
          target_key = model_info[:i18n_field]
          aux = model_info[:aux_field] && task[model_info[:aux_field]] && task[model_info[:aux_field]].to_sym
          task[target_key] ||= i18n_string(i18n,model_name,source,aux) if source
        end
        (task[:children]||[]).map{|t|add_i18n_strings_to_rendered_tasks!(t,i18n)}
      end

      def get_i18n_mappings_for_models(*model_names)
        models_to_cache = model_names.map{|m|(I18nMappingInfo[m]||{})[:models]||[]}.flatten.uniq
        return Hash.new if models_to_cache.empty?
        models_to_cache.inject({}){|h,m|h.merge(m => get_model_i18n(m))}
      end

      I18nMappingInfo = {
        :component => {:models => [:component], :name_field => :component_name, :i18n_field => :component_i18n},
        :attribute => {:models => [:attribute,:component], :name_field => :attribute_name, :i18n_field => :attribute_i18n,:aux_field => :component_name}
      }

      def i18n_string(i18n,model_name,input_string,aux=nil)
        return I18nAux::i18n_string_component(i18n,input_string,aux) if model_name == :component
        return I18nAux::i18n_string_attribute(i18n,input_string,aux) if model_name == :attribute
        return input_string.to_s if model_name == :node
        Log.error("Unexpected model type #{model_name} in i18n string translation")
        I18nAux::translate_input(i18n,model_name,input_string) || input_string.to_s
      end

      def get_i18n_port_name(i18n,port)
        #TODO: this has implcit assumption that port is associated with a certain attribute and component
        attr_name = port.link_def_name()
        cmp_name = port.component_name()
        attr_i18n = I18nAux::i18n_string_attribute(i18n,attr_name)||attr_name
        cmp_i18n = I18nAux::i18n_string_component(i18n,cmp_name)||cmp_name
        #TODO: needs revision; also probably move to model/port
        if [ "component_external", "component_internal_external"].include?(port[:type])
          "#{cmp_i18n} / #{attr_i18n}"
        else
          "#{cmp_i18n} #{port.ref_num().to_s} / #{attr_i18n}"
        end
      end

      module I18nAux
        def self.i18n_string_component(i18n,input_string,aux=nil)
          string = translate_input(i18n,:component,input_string)
          return string if string
          #otherwise use the following heuristic
          input_string.to_s.gsub(XYZ::Model::Delim::RegexpCommon, " ")
        end

        def self.i18n_string_attribute(i18n,input_string,component_type=nil)
          #TODO: stub; not yet using component_type
          proc_input_string,index = ret_removed_array_index(input_string)
          translation = translate_input(i18n,:attribute,proc_input_string)
          ret = (translation ? translation : proc_input_string.to_s)
          if ndx = index_print_form(index) 
            ret += " #{ndx}"
          end 
          ret
        end
        
        def self.translate_input(i18n,model_name,input_string)
          return nil unless input_string and not input_string.empty?
          i18n[model_name][input_string.to_sym]
        end
    
        #returns first array index
        def self.ret_removed_array_index(input_string)
          [input_string.to_s.sub(XYZ::Model::Delim::NumericIndexRegexp,""),$1 && $1.to_i]
        end
    
        def self.capitalize_words(s)
          s.scan(/\w+/).map{|x|x.capitalize}.join(" ")
        end

        def self.index_print_form(index)
          return nil if index.nil?
          return nil if index == 0
          "[#{(index+1).to_s}]"
        end

      end

      def build_js_model_caches(user=nil)
        build_model_defs_js_cache()
        build_model_i18n_js_cache(user)
      end

      def get_model_i18n(model_name,user=nil)
        language = ((user and user.respond_to?(:language)) ? user.language : nil) || R8::Config[:default_language]
        return Cache[model_name][language] if (Cache[model_name] and Cache[model_name][language])

        content = Hash.new
        file_name = "#{R8::Config[:i18n_base_dir]}/#{model_name}/#{language}.rb"
        if File.exists?(file_name) 
          content = eval(IO.read(file_name))
#        else
#          file_name = "#{R8::Config[:i18n_root]}/#{R8::Config[language]}.rb"
#          content = eval(IO.read(file_name)) if File.exists?(file_name)
        end

        file_name = "#{R8::Config[:i18n_base_dir]}/#{model_name}/#{language}.options.rb"
        if File.exists?(file_name) 
          content[:options_list] = eval(IO.read(file_name))
#        else
#          file_name = "#{R8::Config[:i18n_root]}/#{R8::Config[language]}.rb"
#          content = eval(IO.read(file_name)) if File.exists?(file_name)
        end
        content[:options_list] = Hash.new if content[:options_list].nil?
        set_and_ret_cache(model_name,language,content)
      end

      def get_model_options(model_name,user=nil)
        language = ((user and user.respond_to?(:language)) ? user.language : nil) || R8::Config[:default_language]
        return Cache[model_name][language][:options_list] if (Cache[model_name] and Cache[model_name][language] and Cache[model_name][language][:options_list])

        return nil
      end

      def get_model_defs(model_name)
        return Cache[model_name][:model_defs] if (Cache[model_name] and Cache[model_name][:model_defs])

        content = Hash.new
        file_name = "#{R8::Config[:meta_base_dir]}/#{model_name}/model_def.rb"
        if File.exists?(file_name) 
          content = eval(IO.read(file_name))
        end

        Cache[model_name] ||= Hash.new
        Cache[model_name][:model_defs] ||= content
      end


#TODO: build role based cache versions
      def build_model_defs_js_cache()
        set_app_def() unless Cache[:app]

        model_defs = Hash.new
        Cache[:app][:model_list].each do |model|
            model_defs[model] = get_model_defs(model)
        end
        cache_str = 'R8.Model.defs='+JSON.pretty_generate(model_defs)+';'
        cache_file_name = "#{R8::Config[:js_file_write_path]}/model_defs.cache.js"
        File.open(cache_file_name, 'w') {|fhandle|fhandle.write(cache_str)}
      end

#TODO: build language based cache versions
      def build_model_i18n_js_cache(user)
        set_app_def() unless Cache[:app]

        model_i18n = Hash.new
        Cache[:app][:model_list].each do |model|
            model_i18n[model] = get_model_i18n(model,user)
        end

        cache_str = 'R8.Model.i18n='+JSON.pretty_generate(model_i18n)+';'
        cache_file_name = "#{R8::Config[:js_file_write_path]}/model.i18n.cache.js"
        File.open(cache_file_name, 'w') {|fhandle|fhandle.write(cache_str)}
      end

      def set_app_def()
        if(!Cache[:app])
          content = Hash.new
          file_name = "#{R8::Config[:meta_base_dir]}/app_def.rb"
          if File.exists?(file_name) 
            content = eval(IO.read(file_name))
          end

          Cache[:app] ||= content
        end
      end

     private
      Cache = Hash.new
      def set_and_ret_cache(model_name,language,content)
        Cache[model_name] ||= Hash.new
        Cache[model_name][language] ||= content
      end
    end
  end
end



