module DTK; class  Assembly
  class Instance < self
    r8_nested_require('instance','action')
    include ActionMixin

    ### standard get methods
    def get_augmented_node_attributes(filter_proc=nil)
      get_objs_helper(:node_attributes,:attribute,:filter_proc => filter_proc,:augmented => true)
    end

    def get_augmented_node_assembly_attributes(filter_proc=nil)
      get_objs_helper(:node_assembly_attributes,:attribute,:filter_proc => filter_proc,:augmented => true)
    end

    def get_service_add_ons()
      get_objs_helper(:service_add_ons_from_instance,:service_add_on)
    end
    def get_augmented_service_add_ons()
      get_objs_helper(:aug_service_add_ons_from_instance,:service_add_on,:augmented => true)
    end
    def get_augmented_service_add_on(add_on_name)
      filter_proc = lambda{|sao|sao[:display_name] == add_on_name}
      get_obj_helper(:aug_service_add_ons_from_instance,:service_add_on,:filter_proc => filter_proc, :augmented => true)
    end

    def get_nodes(*alt_cols)
      cols = ([:id,:display_name,:group_id] + alt_cols).uniq
      sp_hash = {
        :cols => cols,
        :filter => [:eq, :assembly_id, self[:id]]
      }
      Model.get_objs(model_handle.createMH(:node),sp_hash)
    end

    def get_target()
      get_obj_helper(:target,:target)
    end

    ### end: standard get methods
    def self.delete_and_destroy_its_nodes(assembly_idh)
      #TODO: need to refine to handle case where node hosts multiple assemblies or native components; before that need to modify node isnatnce
      #repo so can point to multiple assembly instances
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:eq, :assembly_id, assembly_idh.get_id]
      }
      assembly_nodes = get_objs(assembly_idh.createMH(:node),sp_hash)
      assembly_nodes.map{|r|r.destroy_and_delete()}
      Model.delete_instance(assembly_idh)
    end

    def add_component(node_idh,component_template_idh)
      #first check that node_idh belongs to this instance
      sp_hash = {
        :cols => [:id, :display_name,:group_id],
        :filter => [:and, [:eq, :id, node_idh.get_id()], [:eq, :assembly_id, id()]]
      }
      unless node = Model.get_obj(model_handle(:node),sp_hash)
        raise ErrorIdInvalid.new(node_idh.get_id(),:node)
      end
      node.add_component(component_template_idh)
    end

    def delete_component(component_idh)
      #first check that component_idh belongs to this instance
      sp_hash = {
        :cols => [:id, :display_name],
        :filter => [:and, [:eq, :id, component_idh.get_id()], [:eq, :assembly_id, id()]]
      }
      unless Model.get_obj(model_handle(:component),sp_hash)
        raise ErrorIdInvalid.new(component_idh.get_id(),:component)
      end
      Model.delete_instance(component_idh)
    end


    def add_sub_assembly(add_on_name, assembly_name=nil)
      aug_service_add_on = get_augmented_service_add_on(add_on_name)
      sub_assembly_template = aug_service_add_on[:sub_assembly_template].copy_as_assembly_template()

      override_attrs = Hash.new
      override_attrs[:display_name] = 
        if assembly_name
          assembly_name 
        else
          update_object!(:display_name)
          #TODO: does not bump up name for multiple insatnces
          "#{self[:display_name]}::#{sub_assembly_template[:display_name]}"
        end
      clone_opts = {
        :ret_new_obj_with_cols => [:id,:type],
        :service_add_on => {
          :base_assembly => self,
          :service_add_on => aug_service_add_on
        }
      }
      target = get_target()
      new_sub_assembly = target.clone_into(sub_assembly_template,override_attrs,clone_opts)
      new_sub_assembly && new_sub_assembly.id_handle()
    end

    def promote_to_library(library_idh=nil)
      #TODO: can make more efficient by increemnt update as opposed to a delete then create
      #see if corresponding template in library and deleet if so 
      if assembly_template = get_associated_template?(library_idh)
        Assembly::Template.delete(assembly_template.id_handle())
      end
      library_idh ||= assembly_template && id_handle(:model_name => :library,:id => assembly_template[:library_library_id])
      #if no library_idh is given and no matching template, use teh public library
      library_idh ||= Library.get_public_library(model_handle.createMH(:library)).id_handle()

      create_library_template_from_assembly(library_idh)
    end

    def create_new_template(service_module,new_template_name)
      service_module.update_object!(:display_name,:library_library_id)
      library_idh = id_handle(:model_name => :library, :id => service_module[:library_library_id])
      service_module_name = service_module[:display_name]

      if Assembly::Template.exists?(library_idh,service_module_name,new_template_name)
        raise ErrorUsage.new("Assembly template (#{new_template_name}) already exists in service module (#{service_module_name})")
      end

      name_info = {
        :service_module_name => service_module_name,
        :assembly_template_name => new_template_name
      }
      create_library_template_from_assembly(library_idh,name_info)
    end      

    def info_about(about,opts={})
      cols = post_process_per_row = order = nil
      order = proc{|a,b|a[:display_name] <=> b[:display_name]}
      case about 
       when :attributes
        ret = get_attributes_print_form_aux(opts[:filter_proc]).map do |a|
          Aux::hash_subset(a,[:id,:display_name,:value])
        end.sort(&order)
        return ret
       when :components
        cols = [:nested_nodes_and_cmps_summary]
        post_process_per_row = proc do |r|
          display_name = "#{r[:node][:display_name]}/#{r[:nested_component][:display_name].gsub(/__/,"::")}"
          r[:nested_component].hash_subset(:id).merge(:display_name => display_name)
        end
       when :nodes
        cols = [:nodes]
        post_process_per_row = proc do |r|
          r[:node].hash_subset(:id,:display_name,:os_type,:external_ref,:type)
        end
       when :tasks
        cols = [:tasks]
        post_process_per_row = proc do |r|
          r[:task]
        end
        order = proc{|a,b|b[:started_at] <=> a[:started_at]}
      end
      unless cols
        raise Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
      rows = get_objs(:cols => cols)
      ret = post_process_per_row ? rows.map{|r|post_process_per_row.call(r)} : rows
      order ? ret.sort(&order) : ret
    end

    def get_attributes_print_form(filter=nil)
      if filter
        case filter
          when :required_unset_attributes
          get_attributes_print_form_aux(lambda{|a|a.required_unset_attribute?()})
          else 
            raise Error.new("not treating filter (#{filter}) in Assembly::Instance#get_attributes_print_form")
        end  
      else
        get_attributes_print_form_aux()
      end
    end

    def get_attributes_print_form_aux(filter_proc=nil)
      assembly_attrs = Array.new #TODO: stub
      component_attrs = get_augmented_node_assembly_attributes(filter_proc).map do |aug_attr|
        Attribute::Pattern::Display.new(aug_attr,:component).print_form()
      end
      node_attrs = get_augmented_node_attributes(filter_proc).map do |aug_attr|
        Attribute::Pattern::Display.new(aug_attr,:node).print_form()
      end

      (assembly_attrs + node_attrs + component_attrs).sort{|a,b|a[:display_name] <=> b[:display_name]}
    end
    private :get_attributes_print_form_aux

    def self.check_valid_id(model_handle,id)
      filter = 
        [:and,
         [:eq, :id, id],
         [:eq, :type, "composite"],
         [:neq, :datacenter_datacenter_id, nil]]
      check_valid_id_helper(model_handle,id,filter)
    end

    def self.name_to_id(model_handle,name)
      parts = name.split("/")
      augmented_sp_hash = 
        if parts.size == 1
          {:cols => [:id],
           :filter => [:and,
                      [:eq, :display_name, parts[0]],
                      [:eq, :type, "composite"],
                      [:neq, :datacenter_datacenter_id, nil]]
          }
        elsif parts.size == 2
          {:cols => [:id,:component_type,:target],
           :filter => [:and,
                      [:eq, :display_name, parts[1]],
                      [:eq, :type, "composite"]],
           :post_filter => lambda{|r|r[:target][:display_name] ==  parts[0]}
          }
      else
        raise ErrorNameInvalid.new(name,pp_object_type())
      end
      name_to_id_helper(model_handle,name,augmented_sp_hash)
    end

    #TODO: probably move to Assembly
    def model_handle(mn=nil)
      super(mn||:component)
    end
    
   private
    def get_associated_template?(library_idh=nil)
      update_object!(:ancestor_id,:component_type,:version,:ui)
      if self[:ancestor_id]
        return id_handle(:id => self[:ancestor_id]).create_object().update_object!(:library_library_id,:ui)
      end
      sp_hash = {
        :cols => [:id,:library_library_id,:ui],
        :filter => [:and, [:eq, :component_type, self[:component_type]],
                    [:neq, :library_library_id, library_idh && library_idh.get_id()],
                    [:eq, :version, self[:version]]]
      }
      rows = Model.get_objs(model_handle(),sp_hash)
      case rows.size
       when 0 then nil
       when 1 then rows.first
       else raise Error.new("Unexpected result: cannot find unique matching assembly template")
      end
    end

    def create_library_template_from_assembly(library_idh,name_info=nil)
      update_object!(:component_type,:version,:ui)
      if self[:version]
        raise Error.new("TODO: not implemented yet AssemblyInstance#create_library_template when version no null")
      end
      if name_info
        service_module_name = name_info[:service_module_name]
        template_name = name_info[:assembly_template_name]
      else
      service_module_name,template_name = Assembly::Template.parse_component_type(self[:component_type])
      end
      ui = self[:ui]
      node_idhs = get_nodes().map{|r|r.id_handle()}
      if node_idhs.empty?
        raise Error.new("Cannot find any nodes associated with assembly (#{self[:display_name]})")
      end
      Assembly::Template.create_library_template(library_idh,node_idhs,template_name,service_module_name,ui)
    end
  end
end 
#TODO: hack to get around error in /home/dtk/server/system/model.r8.rb:31:in `const_get
AssemblyInstance = Assembly::Instance
end

