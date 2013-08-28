module DTK; class Component
  class Instance < self
    def self.component_list_fields()
      [:id,:group_id,:display_name,:component_type,:implementation_id,:basic_type,:version,:only_one_per_node,:external_ref,:node_node_id,:extended_base]
    end

    def self.create_title_attribute(cmp_idh,component_title,title_attr_name=nil)
      title_attr_name ||=  'name'
      ref = title_attr_name
      match_assigns = {:display_name => title_attr_name,:component_component_id => cmp_idh.get_id()}
      create_from_row?(cmp_idh.createMH(:attribute),ref,match_assigns,{:value_asserted=>component_title})
    end

    def self.add_titles!(cmps)
      ret = cmps
      #TODO: may make this be field in component instance
      cmps_needing_titles = cmps.select do |cmp|
        cmp[:title].nil? and cmp.get_field?(:only_one_per_node) == false
      end
      return ret if cmps_needing_titles.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_component_id,:title],
        :filter => [:oneof, :component_component_id, cmps_needing_titles.map{|cmp|cmp[:id]}]
      }
      ndx_attrs = Hash.new
      get_objs(cmps.first.model_handle(:attribute),sp_hash).each do |a|
        if title = a[:title]
          ndx_attrs[a[:component_component_id]] = title
        end
      end
      cmps_needing_titles.each do |cmp|
        if title = ndx_attrs[cmp[:id]]
          cmp[:title] = title
        end
      end
      ret
    end

    def self.get_ndx_intra_node_rels(cmp_idhs)
      cmps_with_deps = Component::Instance.get_components_with_dependency_info(cmp_idhs)
      ComponentOrder.get_ndx_cmp_type_and_derived_order(cmps_with_deps)
    end

    #TODO: may be able to deprecate below seeing that dependencies are on instances
    def self.get_components_with_dependency_info(cmp_idhs)
      ret = Array.new
      return ret if cmp_idhs.empty?
      sp_hash = {
        :cols => [:id,:inherited_dependencies, :extended_base, :component_type],
        :filter => [:oneof, :id, cmp_idhs.map{|idh|idh.get_id()}]
      }
      cmp_mh = cmp_idhs.first.createMH()
      Model.get_objs(cmp_mh,sp_hash)
    end

    def self.print_form(component)
      component.get_field?(:display_name).gsub(/__/,"::")
    end

    def self.version_print_form(component)
      ModuleBranch.version_from_version_field(component.get_field?(:version))
    end

  end
end; end
