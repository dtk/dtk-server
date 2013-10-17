module DTK; class Component
  class Template < self
    def self.get_objs(mh,sp_hash,opts={})
      if mh[:model_name] == :component_template
        super(mh.merge(:model_name=>:component),sp_hash,opts).map{|cmp|create_from_component(cmp)}
      else
        super
      end
    end

    def self.create_from_component(cmp)
      cmp && cmp.id_handle().create_object(:model_name => :component_template).merge(cmp)
    end

    def self.get_info_for_clone(cmp_template_idhs)
      ret = Array.new
      return ret if cmp_template_idhs.empty?
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:project_project_id,:component_type,:version,:module_branch],
        :filter => [:oneof,:id,cmp_template_idhs.map{|idh|idh.get_id()}]
      }
      mh = cmp_template_idhs.first.createMH(:component_template)
      ret = get_objs(mh,sp_hash)
      ret.each{|r|r.get_current_sha!()}
      ret
    end

    def update_with_clone_info!()
      clone_info = self.class.get_info_for_clone([id_handle()]).first
      merge!(clone_info)
    end

    def get_current_sha!()
      unless module_branch = self[:module_branch]
        Log.error("Unexpected that get_current_sha called on object when self[:module_branch] not set")
        return nil
      end
      module_branch[:current_sha] || module_branch.update_current_sha_from_repo!()
    end

    def get_component_module()
      get_obj_helper(:component_module)
    end

    def get_dependencies_simple()
      sp_hash = {
        :cols => [:id,:group_id,:component_component_id,:search_pattern,:type,:description,:severity],
        :filter => [:eq,:component_component_id,id()]
      }
      Model.get_objs(model_handle(:dependency),sp_hash)
    end

    #returns non-nil only if this is a component that takes a title and if so returns the attribute object that stores the title
    def get_title_attribute_name?()
      rows = self.class.get_title_attributes([id_handle])
      rows.first[:display_name] unless rows.empty?
    end

    #for any member of cmp_tmpl_idhs that is a non-singleton, it returns the title attribute
    def self.get_title_attributes(cmp_tmpl_idhs)
      ret = Array.new
      return ret if cmp_tmpl_idhs.empty?
      #first see if not only_one_per_node and has the default attribute
      sp_hash = {
        :cols => [:attribute_default_title_field],
        :filter => [:and,[:eq,:only_one_per_node,false],
                    [:oneof,:id,cmp_tmpl_idhs.map{|idh|idh.get_id()}]]
      }
      rows = get_objs(cmp_tmpl_idhs.first.createMH(),sp_hash)
      return ret if rows.empty?
      
      #rows will have element for each element of cmp_tmpl_idhs that is non-singleton
      #element key :attribute will be nil if it does not use teh default key; for all 
      #these we need to make the more expensive call Attribute.get_title_attributes
      need_title_attrs_cmp_idhs = rows.select{|r|r[:attribute].nil?}.map{|r|r.id_handle()}
      ret = rows.map{|r|r[:attribute]}.compact
      unless need_title_attrs_cmp_idhs.empty?
        ret += Attribute.get_title_attributes(need_title_attrs_cmp_idhs)
      end
      ret
    end

    #type_version_list is an array with each element having keys :component_type, :version_field
    def self.get_matching_type_and_version(project_idh,type_version_field_list,opts={})
      ret = Array.new
      cmp_types = type_version_field_list.map{|r|r[:component_type]}.uniq
      versions = type_version_field_list.map{|r|r[:version_field]}
      sp_hash = {
        :cols => [:id,:group_id,:component_type,:version,:implementation_id],
        :filter => [:and, [:eq, :project_project_id, project_idh.get_id()],
                    [:oneof, :version, versions],
                    [:eq, :assembly_id, nil], #so get component templates, not components on assembly instances
                    [:oneof, :component_type, cmp_types]]
      }
      component_rows = get_objs(project_idh.createMH(:component),sp_hash)

      ret = Array.new
      unmatched = Array.new
      type_version_field_list.each do |tv|
        if match = component_rows.find{|r|tv[:version_field] == r[:version] and tv[:component_type] == r[:component_type]}
          ret << match
        else
          unmatched << tv
        end
      end
      if opts[:raise_errors_if_unmatched] and not unmatched.empty?()
        ct_print_form = unmatched.map do |r|
          r[:version] ? "#{r[:component_type]}:#{r[:version]}" : r[:component_type]
        end.join(',')
        raise Error.new("No match for component templates (#{ct_print_form})")
      end
      ret
    end
      
    def self.list(mh,opts=Opts.new)
      unless project_idh = opts[:project_idh]
        raise Error.new("Requires opts[:project_idh]")
      end
      sp_hash = {
        :cols => [:id, :type, :display_name, :description, :component_type, :version, :refnum],
        :filter => [:and, [:eq, :type, "template"], 
                    [:eq, :assembly_id, nil], #so get component templates, not components on assembly instances
                    [:eq, :project_project_id, project_idh.get_id()]]
      }
      ret = get_objs(project_idh.createMH(:component),sp_hash,:keep_ref_cols => true)
      if constraint = opts[:component_version_constraints]
        ret = ret.select{|r|constraint.meets_constraint?(r)}
      end
      ret.each{|r|r.convert_to_print_form!()}
      ret.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    def self.check_valid_id(model_handle,id)
      filter = 
        [:and,
         [:eq, :id, id],
         [:eq, :type, "template"],
         [:eq, :node_node_id, nil],
         [:neq, :project_project_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end
    def self.name_to_id(model_handle,name,version=nil)
      sp_hash = {
        :cols => [:id],
        :filter => [:and,
                    [:eq, :component_type, Component.component_type_from_user_friendly_name(name)],
                    [:neq, :project_project_id, nil],
                    [:eq, :node_node_id, nil],
                    [:eq, :version, version_field(version)]]
      }
      name_to_id_helper(model_handle,version_display_name(name,version),sp_hash)
    end
  end

  #TODO: may move to be instance method on Template
  module TemplateMixin
    def update_default(attribute_name,val,field_to_match=:display_name)
      tmpl_attr_obj =  get_virtual_attribute(attribute_name,[:id,:value_asserted],field_to_match)
      raise Error.new("cannot find attribute #{attribute_name} on component template") unless tmpl_attr_obj
      update(:updated => true)
      tmpl_attr_obj.update(:value_asserted => val)
      #update any instance that points to this template, which does not have an instance value asserted
      #TODO: can be more efficient by doing selct and update at same time
      base_sp_hash = {
        :model_name => :component,
        :filter => [:eq, :ancestor_id, id()],
        :cols => [:id]
      }
      join_array = 
        [{
           :model_name => :attribute,
           :convert => true,
           :join_type => :inner,
           :filter => [:and, [:eq, field_to_match, attribute_name], [:eq, :is_instance_value,false]],
           :join_cond => {:component_component_id => :component__id},
           :cols => [:id,:component_component_id]
         }]
      attr_ids_to_update = Model.get_objects_from_join_array(model_handle,base_sp_hash,join_array).map{|r|r[:attribute][:id]}
      unless attr_ids_to_update.empty?
        attr_mh = createMH(:attribute)
        attribute_rows = attr_ids_to_update.map{|attr_id|{:id => attr_id, :value_asserted => val}}
        Attribute.update_and_propagate_attributes(attr_mh,attribute_rows)
      end
    end

  end
end; end

