module Ramaze::Helper
  module I18nStringMapping
    include R8Tpl::Utility::I18n
    def add_i18n_strings_to_rendered_tasks!(task,i18n={})
      model_name = task[:level] && task[:level].to_sym
      if model_info = MappingInfo[model_name]
        model_info[:models].each{|m|i18n[m] ||= get_model_i18n(m)}
        source = task[model_info[:name_field]]
        target_key = model_info[:i18n_field]
        aux = model_info[:aux_field] && task[model_info[:aux_field]] && task[model_info[:aux_field]].to_sym
        task[target_key] ||= i18n_string(i18n,model_name,source,aux) if source
      end
      (task[:children]||[]).map{|t|add_i18n_strings_to_rendered_tasks!(t,i18n)}
    end
    MappingInfo = {
      :component => {:models => [:component], :name_field => :component_name, :i18n_field => :component_i18n},
      :attribute => {:models => [:attribute,:component], :name_field => :attribute_name, :i18n_field => :attribute_i18n,:aux_field => :component_name}
    }
  
    def get_i18n_mappings_for_models(*model_names)
      models_to_cache = model_names.map{|m|(MappingInfo[m]||{})[:models]||[]}.flatten.uniq
      return Hash.new if models_to_cache.empty?
      models_to_cache.inject({}){|h,m|h.merge(m => get_model_i18n(m))}
    end

    def i18n_string(i18n,model_name,input_string,aux=nil)
      return i18n_string_component(i18n,input_string,aux) if model_name == :component
      return i18n_string_attribute(i18n,input_string,aux) if model_name == :attribute
      return input_string.to_s if model_name == :node
      Log.error("Unexpected model type #{model_name} in i18n string translation")
      translate_input(i18n,model_name,input_string) || input_string.to_s
    end
    
    def i18n_string_component(i18n,input_string,aux=nil)
      string = translate_input(i18n,:component,input_string)
      return string if string
      #otherwise use the following heuristic
      input_string.to_s.gsub(XYZ::Model::Delim::RegexpCommon, " ")
    end

    def i18n_string_attribute(i18n,input_string,component_input_string=nil)
      #TODO: stub
      proc_input_string,index = ret_removed_array_index(input_string)
      ret = index_print_form(index) 
      ret += " " unless ret.empty?
      ret += (translate_input(i18n,:attribute,proc_input_string)||proc_input_string.to_s)
      capitalize_words(ret)
    end

    def translate_input(i18n,model_name,input_string)
      i18n[model_name][input_string.to_sym]
    end
    
    #returns first array index
    def ret_removed_array_index(input_string)
      [input_string.to_s.sub(XYZ::Model::Delim::NumericIndexRegexp,""),$1 && $1.to_i]
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
end
