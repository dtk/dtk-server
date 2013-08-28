module DTK; class Component
  class Template < self

    #type_version_list is an array with each element having keys :component_type, :version_field
    def self.get_matching_type_and_version(project_idh,type_version_field_list,opts={})
      ret = Array.new
      cmp_types = type_version_field_list.map{|r|r[:component_type]}.uniq
      versions = type_version_field_list.map{|r|r[:version_field]}
      sp_hash = {
        :cols => [:id,:group_id,:component_type,:version],
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
        :filter => [:and, [:eq, :type, "template"], [:eq, :project_project_id, project_idh.get_id()]]
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

