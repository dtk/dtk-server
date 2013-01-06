r8_nested_require('template','version_constraints')
module DTK; class Component
  class Template < self
    #MOD_RESTRUCT: TODO: when deprecate self.list__library_parent(mh,opts={}), sub .list__project_parent for this method
    def self.list(mh,opts)
      if project_id = opts[:project_idh]
        ndx_ret = list__library_parent(mh,opts).inject(Hash.new) do |h,r|
          ndx = version_display_name(r[:display_name],nil)
          h.merge(ndx => r)
        end
        list__project_parent(opts[:project_idh],opts).each do |r|
          ndx = version_display_name(r[:display_name],r[:version])
          ndx_ret[ndx] ||= r
        end
        ndx_ret.values.sort{|a,b|a[:display_name] <=> b[:display_name]}
      else
        list__library_parent(mh,opts)
      end
    end
    def self.list__project_parent(project_idh,opts={})
      sp_hash = {
        :cols => [:id, :type, :display_name, :description, :component_type, :version, :refnum],
        :filter => [:and, [:eq, :type, "template"], [:eq, :project_project_id, project_idh.get_id()]]
      }
      ret = get_objs(project_idh.createMH(:component),sp_hash,:keep_ref_cols => true)
      if constraint = opts[:component_version_constraints]
        ret = ret.select{|r|constraint.meets_constraint?(r)}
      end
      ret.each{|r|r.convert_to_print_form!()}
      ret.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end
    #MOD_RESTRUCT: TODO: deprecate below for above
    def self.list__library_parent(model_handle,opts={})
      library_filter = (opts[:library_idh] ? [:eq, :library_library_id, opts[:library_idh].get_id()] : [:neq, :library_library_id, nil])
      sp_hash = {
        :cols => [:id, :type, :display_name, :description],
        :filter => [:and, [:eq, :type, "template"], library_filter]
      }
      ret = get_objs(model_handle.createMH(:component),sp_hash)
      ret.each{|r|r.convert_to_print_form!()}
      ret.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    #MOD_RESTRUCT: TODO: when deprecate library parent forms replace this by project parent forms
    def self.check_valid_id(model_handle,id)
      begin
        check_valid_id__library_parent(model_handle,id)
       rescue ErrorIdInvalid 
        check_valid_id__project_parent(model_handle,id)
      end
    end
    def self.name_to_id(model_handle,name,version=nil)
      if version
        name_to_id__project_parent(model_handle,name,version)
      else
        begin
          name_to_id__library_parent(model_handle,name)
         rescue ErrorNameDoesNotExist
          name_to_id__project_parent(model_handle,name)
        end
      end
    end
    def self.check_valid_id__project_parent(model_handle,id)
      filter = 
        [:and,
         [:eq, :id, id],
         [:eq, :type, "template"],
         [:neq, :project_project_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end
    def self.name_to_id__project_parent(model_handle,name,version=nil)
      sp_hash = {
        :cols => [:id],
        :filter => [:and,
                    [:eq, :component_type, Component.component_type_from_user_friendly_name(name)],
                    [:neq, :project_project_id, nil],
                    [:eq, :version, version_field(version)]]
      }
      name_to_id_helper(model_handle,version_display_name(name,version),sp_hash)
    end
    #MOD_RESTRUCT: TODO: deprecate below for above
    def self.check_valid_id__library_parent(model_handle,id)
      filter = 
        [:and,
         [:eq, :id, id],
         [:eq, :type, "template"],
         [:neq, :library_library_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end
    def self.name_to_id__library_parent(model_handle,name)
      sp_hash = {
        :cols => [:id],
        :filter => [:and,
                    [:eq, :component_type, Component.component_type_from_user_friendly_name(name)],
                    [:neq, :library_library_id, nil]]
      }
      name_to_id_helper(model_handle,name,sp_hash)
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

