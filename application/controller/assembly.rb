module XYZ
  class AssemblyController < Controller

    def test_get_items(id)
      assembly = id_handle(id,:component).create_object()
      item_list = assembly.get_items()

      return {
        :data=>item_list
      }
    end

    def search
      params = request.params.dup
      cols = model_class(:component).common_columns()

      filter_conjuncts = params.map do |name,value|
        [:regex,name.to_sym,"^#{value}"] if cols.include?(name.to_sym)
      end.compact

      #restrict results to belong to library and not nested in assembly
      filter_conjuncts += [[:neq,:library_library_id,nil],[:eq,:assembly_id,nil]]
      sp_hash = {
        :cols => cols,
        :filter => [:and] + filter_conjuncts
      }
      component_list = Model.get_objs(model_handle(:component),sp_hash).each{|r|r.materialize!(cols)}

      i18n = get_i18n_mappings_for_models(:component)
      component_list.each_with_index do |model,index|
        component_list[index][:model_name] = :component
        body_value = ''
        component_list[index][:ui] ||= {}
        component_list[index][:ui][:images] ||= {}
        name = component_list[index][:display_name]
        title = name.nil? ? "" : i18n_string(i18n,:component,name)
        
#TODO: change after implementing all the new types and making generic icons for them
        model_type = 'service'
        model_sub_type = 'db'
        model_type_str = "#{model_type}-#{model_sub_type}"
        prefix = "#{R8::Config[:base_images_uri]}/v1/componentIcons"
        png = component_list[index][:ui][:images][:tnail] || "unknown-#{model_type_str}.png"
        component_list[index][:image_path] = "#{prefix}/#{png}"

        component_list[index][:i18n] = title
      end

      return {:data=>component_list}
    end

  end
end