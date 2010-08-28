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

        set_and_ret_cache(model_name,language,content)
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
