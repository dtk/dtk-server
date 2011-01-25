module Ramaze::Helper
  module I18nStringMapping
    include R8Tpl::Utility::I18n
=begin
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
=end
  def add_i18n_strings_to_rendered_tasks!(task,i18n={})
    model_name = task[:level] && task[:level].to_sym
    if model_info = MappingInfo[model_name]
      model_info[:models].each{|m|i18n[m] ||= get_model_i18n(m)}
      source = task[model_info[:name_field]]
      target_key = model_info[:i18n_field]
      task[target_key] ||= i18n_string(i18n,model_name,source.to_sym) if source
      end
      (task[:children]||[]).map{|t|add_i18n_strings_to_rendered_tasks!(t,i18n)}
    end
    MappingInfo = {
    :component => {:models => [:component], :name_field => :component_name, :i18n_field => :component_i18n},
    :attribute => {:models => [:attribute,:component], :name_field => :attribute_name, :i18n_field => :attribute_i18n}
    }
  end

  def i18n_string(i18n,model_name,key)
    return i18n_string_component(i18n,key) if model_name == :component
    return i18n_string_attribute(i18n,key) if model_name == :attribute
    Log.error("Unexpected model type #{model_name} in i18n string translation")
    i18n[model_name][key]||key.to_s
  end

  def i18n_string_component(i18n,key)
    string = i18n[:component][key]
    return string if string
    #otherwise use the following heuristic
    key.to_s.gsub(XYZ::Model::Delim::RegexpCommon, " ")
  end

  def i18n_string_attribute(i18n,key)
    #TODO: stub
    proc_key,index = ret_removed_array_index(key)
    ret = index_print_form(index) 
    ret += " " unless ret.empty?
    ret += (i18n[:attribute][proc_key]||proc_key.to_s)
    capitalize_words(ret)
  end

  #returns first array index
  def ret_removed_array_index(key)
    [key.to_s.sub(XYZ::Model::Delim::NumericIndexRegexp,"").to_sym,$1 && $1.to_i]
  end

  def capitalize_words(s)
    s.scan(/\w+/).map{|x|x.capitalize}.join(" ")
  end

  def index_print_form(index)
    return "" unless index
    IndexPrintForm[index]||"nth"
  end
  IndexPrintForm = 
    [
     "",
     "second",
     "third"
    ]

end
