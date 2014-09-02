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

    # returns non-nil only if this is a component that takes a title and if so returns the attribute object that stores the title
    def get_title_attribute_name?()
      rows = self.class.get_title_attributes([id_handle])
      rows.first[:display_name] unless rows.empty?
    end

    # for any member of cmp_tmpl_idhs that is a non-singleton, it returns the title attribute
    def self.get_title_attributes(cmp_tmpl_idhs)
      ret = Array.new
      return ret if cmp_tmpl_idhs.empty?
      # first see if not only_one_per_node and has the default attribute
      sp_hash = {
        :cols => [:attribute_default_title_field],
        :filter => [:and,[:eq,:only_one_per_node,false],
                    [:oneof,:id,cmp_tmpl_idhs.map{|idh|idh.get_id()}]]
      }
      rows = get_objs(cmp_tmpl_idhs.first.createMH(),sp_hash)
      return ret if rows.empty?
      
      # rows will have element for each element of cmp_tmpl_idhs that is non-singleton
      # element key :attribute will be nil if it does not use teh default key; for all 
      # these we need to make the more expensive call Attribute.get_title_attributes
      need_title_attrs_cmp_idhs = rows.select{|r|r[:attribute].nil?}.map{|r|r.id_handle()}
      ret = rows.map{|r|r[:attribute]}.compact
      unless need_title_attrs_cmp_idhs.empty?
        ret += Attribute.get_title_attributes(need_title_attrs_cmp_idhs)
      end
      ret
    end

    class MatchElement < Hash
      def initialize(hash)
        super()
        replace(hash)
      end
      def component_type()
        self[:component_type]
      end
      def version_field()
        self[:version_field]
      end
      def version()
        self[:version]
      end
      def namespace()
        self[:namespace]
      end
    end
    def self.get_matching_elements(project_idh,match_element_array,opts={})
      ret = Array.new
      cmp_types = match_element_array.map{|el|el.component_type}.uniq
      versions = match_element_array.map{|el|el.version_field}
      sp_hash = {
        :cols => [:id,:group_id,:component_type,:version,:implementation_id],
        :filter => [:and, 
                    [:eq, :project_project_id, project_idh.get_id()],
                    [:oneof, :version, versions],
                    [:eq, :assembly_id, nil], 
                    [:eq, :node_node_id, nil],
                    [:oneof, :component_type, cmp_types]]
      }
      component_rows = get_objs(project_idh.createMH(:component),sp_hash)
      augment_with_namespace!(component_rows)
      ret = Array.new
      unmatched = Array.new
      match_element_array.each do |el|
        matches = component_rows.select do |r|
          el.version_field == r[:version] and 
            el.component_type == r[:component_type] and
            (el.namespace.nil? or el.namespace == r[:namespace])
        end
        if matches.empty?
          unmatched << el
        elsif matches.size == 1
          ret << matches.first
        else
          # TODO: may put in logic that sees if one is service modules ns and uses that one when multiple matches
          module_name = Component.module_name(el.component_type)
          error_params = {
            :module_type => 'component',
            :module_name => Component.module_name(el.component_type),
            :namespaces => matches.map{|m|m[:namespace]}.compact # compact just to be safe
          }
          raise ServiceModule::ParsingError::AmbiguousModuleRef.new(error_params)
        end
      end
      unless unmatched.empty?()
        # TODO: indicate whether there is a nailed namespace that does not exist or no matches at all
        cmp_refs = unmatched.map do |match_el|
          {
            :component_type => match_el.component_type,
            :version => match_el.version
          }
        end
        raise ServiceModule::ParsingError::DanglingComponentRefs.new(cmp_refs)
      end
      ret
    end
      
    def self.list(mh,opts=Opts.new)
      unless project_idh = opts[:project_idh]
        raise Error.new("Requires opts[:project_idh]")
      end

      sp_hash = {
        :cols => [:id, :type, :display_name, :description, :component_type, :version, :refnum, :module_branch_id],
        :filter => [:and, [:eq, :type, "template"], 
                    [:eq, :assembly_id, nil], #so get component templates, not components on assembly instances
                    [:eq, :project_project_id, project_idh.get_id()]]
      }
      cmps = get_objs(project_idh.createMH(:component),sp_hash,:keep_ref_cols => true)

      ingore_type = opts[:ignore]
      ret = []
      cmps.each do |r|
        sp_h = {
          :cols => [:id, :type, :display_name, :component_module_namespace_info],
          :filter => [:eq, :id, r[:module_branch_id]]
        }
        m_branch = Model.get_obj(project_idh.createMH(:module_branch),sp_h)
        # ret << r unless m_branch[:type].eql?(ingore_type)
        if(m_branch && !m_branch[:type].eql?(ingore_type))
          branch_namespace = m_branch[:namespace]
          r[:namespace] = branch_namespace[:display_name]
          ret << r
        end
      end

      if constraint = opts[:component_version_constraints]
        ret = ret.select{|r|constraint.meets_constraint?(r)}
      end
      ret.each{|r|r.convert_to_print_form!()}
      ret.sort{|a,b|a[:display_name] <=> b[:display_name]}
    end

    def self.check_valid_id(model_handle,id,version_or_versions=nil)
      if version_or_versions.kind_of?(Array)
        version_or_versions.each do |version|
          if ret = check_valid_id_aux(model_handle,id,version,:no_error_if_no_match=>true)
            return ret
          end
        end
        raise ErrorIdInvalid.new(id,pp_object_type())
      else
        check_valid_id_aux(model_handle,id,version_or_versions)
      end
    end

    def self.check_valid_id_aux(model_handle,id,version,opts={})
      filter = 
        [:and,
         [:eq, :id, id],
         [:eq, :type, "template"],
         [:eq, :node_node_id, nil],
         [:neq, :project_project_id, nil],
         [:eq,:version,version_field(version)]]
      check_valid_id_helper(model_handle,id,filter,opts)
    end

    # if title is in the name, this strips it off
    def self.name_to_id(model_handle,name,version_or_versions=nil)
      if version_or_versions.kind_of?(Array)
        version_or_versions.each do |version|
          if ret = name_to_id_aux(model_handle,name,version,:no_error_if_no_match=>true)
            return ret
          end
        end
        raise ErrorNameDoesNotExist.new(name,pp_object_type())
      else
        name_to_id_aux(model_handle,name,version_or_versions)
      end
    end

    def self.get_cmp_template_from_name_with_namespace(cmp_mh, cmp_name, namespace, assembly)
      ret_cmp, match_cmps = nil, []
      display_name = display_name_from_user_friendly_name(cmp_name)
      component_type,title =  ComponentTitle.parse_component_display_name(display_name)
      sp_hash = {
        :cols => [:id, :display_name, :module_branch_id, :type, :ref, :namespace_info_for_cmps],
        :filter => [:and,
                    [:eq, :display_name, display_name],
                    [:eq, :type, 'template'],
                    [:eq, :component_type, component_type],
                    [:neq, :project_project_id, nil],
                    [:eq, :node_node_id, nil]]
      }
      cmps = Model.get_objs(cmp_mh,sp_hash,:keep_ref_cols=>true)

      if namespace
        cmps.select!{|c| (c[:namespace] && c[:namespace][:display_name] == namespace)}
        ret_cmp = cmps.first
      else
        return cmps.first if cmps.size == 1

        opts = Opts.new(:with_namespace => true)
        cmp_modules_for_assembly = assembly.list_component_modules(opts)

        cmp_modules_for_assembly.each do |cmp_mod|
          cmps.each do |cmp|
            if cmp_module = cmp[:component_module]
              match_cmps << cmp if cmp_module[:id] == cmp_mod[:id]
            end
          end

          raise ErrorUsage.new("Multiple components matching component name you provided. Please use namespace:component format to add new component!") if match_cmps.size > 1
          ret_cmp = match_cmps.first
        end
      end

      ret_cmp
    end

   private 
    # if title is in the name, this strips it off
    def self.name_to_id_aux(model_handle,name,version,opts={})
      display_name = display_name_from_user_friendly_name(name)
      component_type,title =  ComponentTitle.parse_component_display_name(display_name)
      sp_hash = {
        :cols => [:id],
        :filter => [:and,
                    [:eq, :type, 'template'],
                    [:eq, :component_type, component_type],
                    [:neq, :project_project_id, nil],
                    [:eq, :node_node_id, nil],
                    [:eq, :version, version_field(version)]]
      }
      name_to_id_helper(model_handle,Component.name_with_version(name,version),sp_hash,opts)
    end

    def self.augment_with_namespace!(component_templates)
      ret = Array.new
      return ret if component_templates.empty?
      sp_hash = {
        :cols => [:id,:namespace_info],
        :filter => [:oneof, :id, component_templates.map{|r|r.id()}]
      }
      mh = component_templates.first.model_handle()
      ndx_namespace_info = get_objs(mh,sp_hash).inject(Hash.new) do |h,r|
        h.merge(r[:id] => (r[:namespace]||{})[:display_name])
      end
      component_templates.each do |r|
        if namespace = ndx_namespace_info[r[:id]]
          r.merge!(:namespace => namespace)
        end
      end
      component_templates
    end
  end

  # TODO: may move to be instance method on Template
  module TemplateMixin
    def update_default(attribute_name,val,field_to_match=:display_name)
      tmpl_attr_obj =  get_virtual_attribute(attribute_name,[:id,:value_asserted],field_to_match)
      raise Error.new("cannot find attribute #{attribute_name} on component template") unless tmpl_attr_obj
      update(:updated => true)
      tmpl_attr_obj.update(:value_asserted => val)
      # update any instance that points to this template, which does not have an instance value asserted
      # TODO: can be more efficient by doing selct and update at same time
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

