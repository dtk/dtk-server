module R8Tpl
  module Utility
    module I18n
      def get_model_i18n(model_name,user)
        user_language = nil #TODO: stub to pull (if it exists language from user object
        language = user_language || R8::Config[:default_language]
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

      def get_model_options(model_name)
        user_language = nil #TODO: stub to pull (if it exists language from user object
        language = user_language || R8::Config[:default_language]
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
        if(!Cache[:app])
          set_app_def()
        end

        model_defs = Hash.new
        Cache[:app][:model_list].each do |model|
            model_defs[model] = get_model_defs(model)
        end
        cache_str = 'R8.Model.defs='+JSON.pretty_generate(model_defs)+';'
        cache_file_name = "#{R8::Config[:js_file_write_path]}/model_defs.cache.js"
        cache_file_handle = File.open(cache_file_name, 'w')
        cache_file_handle.write(cache_str)
        cache_file_handle.close
      end

#TODO: build language based cache versions
      def build_model_i18n_js_cache(user)
        if(!Cache[:app])
          set_app_def()
        end

        model_i18n = Hash.new
        Cache[:app][:model_list].each do |model|
            model_i18n[model] = get_model_i18n(model,user)
        end

        cache_str = 'R8.Model.i18n='+JSON.pretty_generate(model_i18n)+';'
        cache_file_name = "#{R8::Config[:js_file_write_path]}/model.i18n.cache.js"
        cache_file_handle = File.open(cache_file_name, 'w')
        cache_file_handle.write(cache_str)
        cache_file_handle.close
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



