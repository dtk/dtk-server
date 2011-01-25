module Ramaze::Helper
  module I18nStringMapping
    include XYZ
    include R8Tpl::Utility::I18n
    def add_i18n_strings_to_rendered_tasks!(task,i18n=nil)
      model_name = task[:level] && task[:level].to_sym
      if model_name and KeysToMap.keys.include?(model_name)
        i18n ||= KeysToMap.keys.inject({}){|h,m|h.merge(m => get_model_i18n(m))}
        source = task[KeysToMap[model_name][0]]
        target_key = KeysToMap[model_name][1]
        task[target_key] ||= i18n_string(i18n[model_name],model_name,source.to_sym) if source
      end
      (task[:children]||[]).map{|t|add_i18n_strings_to_rendered_tasks!(t)}
    end
    KeysToMap = {
      :component => [:component_name,:component_i18n],
      :attribute => [:attribute_name,:attribute_i18n],
    }
  end

  def i18n_string(i18n_mappings,model_name,key)
    return i18n_string_component(i18n_mappings,key) if model_name == :component
    return i18n_string_attribute(i18n_mappings,key) if model_name == :attribute
    Log.error("Unexpected model type #{model_name} in i18n string translation")
    i18n_mappings[key]||key
  end

  def i18n_string_component(i18n_mappings,key)
    string = i18n_mappings[key]
    return string if string
    #otherwise use the following heuristic
    key.gsub(Delim::Regexp, " ")
  end
  def i18n_string_attribute(i18n_mappings,key)
    #TODO: stub
    i18n_mappings[key]
  end
end
