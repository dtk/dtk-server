module DTK; class Component
  class Instance < self
    def self.get_objs(mh,sp_hash,opts={})
      #TODO: might want to change to :model_name == component_instance
      if mh[:model_name] == :component
        super.map{|cmp|create_from_component(cmp)}
      else
        super
      end
    end

    def self.create_from_component(cmp)
      cmp && cmp.id_handle().create_object(:model_name => :component_instance).merge(cmp)
    end

    def self.component_list_fields()
      [:id,:group_id,:display_name,:component_type,:implementation_id,:basic_type,:version,:only_one_per_node,:external_ref,:node_node_id,:extended_base]
    end

    def self.get_matching?(node_idh,component_type,component_title)
      sp_hash = {
        :cols => [:id,:display_name,:component_type,:ref],
        :filter => [:and,[:eq,:node_node_id,node_idh.get_id()],
                    [:eq,:ref,ComponentTitle.ref_with_title(component_type,component_title)]]
      }
      ret = Model.get_obj(node_idh.createMH(:component),sp_hash)
      ret && component_template_from_component(ret)
    end

    def self.set_title_attribute(cmp_idh,component_title,title_attr_name=nil)
      title_attr_name ||=  'name'
      ref = title_attr_name
      sp_hash = {
        :cols => [:id,:value_asserted],
        :filter => [:and,[:eq,:display_name,title_attr_name],
                    [:eq,:component_component_id,cmp_idh.get_id()]]
      }
      unless title_attr = get_obj(cmp_idh.createMH(:attribute),sp_hash)
        Log.error("Unexpected that cannot find the title attribute")
        return
      end
      unless title_attr[:value_asserted]
        Log.error("Unexpected that title attribute has value_asserted when set_title_attribute called")
      end
      title_attr.update(:value_asserted=>component_title,:cannot_change=>true,:is_instance_value=>true)
    end

    def add_title_field?()
      self.class.add_title_fields?([self])
      self
    end
    def self.add_title_fields?(cmps)
      ret = cmps
      #TODO: for efficiency can look at ref it exsits and see if it indicates a title
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

    def get_component_template_parent()
      unless row = get_obj(:cols => [:instance_component_template_parent])
        raise Error.new("Unexpected that get_component_template_parent() called and nil result")
      end
      Component::Template.create_from_component(row[:component_template])
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

    def print_form()
      self.class.print_form(self)
    end

    def self.print_form(component)
      component.get_field?(:display_name).gsub(/__/,"::")
    end

    def self.version_print_form(component)
      ModuleBranch.version_from_version_field(component.get_field?(:version))
    end
   private
    def self.component_template_from_component(cmp)
      cmp.id_handle().create_object(:model_name => :component_instance).merge(cmp)
    end
  end
end; end
