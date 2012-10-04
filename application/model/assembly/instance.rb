module DTK
  class AssemblyInstance < Assembly
    r8_nested_require('instance','action')
    include ActionMixin
    def promote_to_library(library_idh=nil)
      #TODO: can make more efficient by increemnt update as opposed to a delete then create
      #see if corresponding template in library and deleet if so 
      if assembly_template = get_associated_template?(library_idh)
        AssemblyTemplate.delete(assembly_template.id_handle())
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

      if AssemblyTemplate.exists?(library_idh,service_module_name,new_template_name)
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
        ret = get_attributes(opts[:filter_proc]).map do |a|
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
          r[:node].hash_subset(:id,:display_name,:os_type,:external_ref, {:type => :node_type})
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

    def get_missing_parameters()
      get_attributes().select do |a|
        a[:required] #and not a[:value]
      end.map do |a|
        datatype = 
          case a[:data_type]
            when "integer" then "integer"
            when "boolean" then "boolean"
          else "string"
          end
        {
          :id => a[:id],
          :display_name => a[:display_name],
          :datatype => datatype,
          :description => a[:description]
        }
      end
    end

    def get_attributes(filter_proc=nil)
      assembly_attrs = Array.new #TODO: stub
      component_attrs = get_objs(:cols => [:node_assembly_attributes]).map do |r|
        attr = r[:attribute]
        #TODO: more efficient to have sql query do filtering
        if filter_proc.nil? or filter_proc.call(attr)
          display_name = "#{r[:node][:display_name]}/#{r[:nested_component][:display_name].gsub(/__/,"::")}/#{attr[:display_name]}"
          value = attr[:attribute_value]
          #TODO: handle complex attributes better and omit derived attributes; may also indiacte whether teher is an override
          attr.hash_subset(:id,:required,:data_type,:description).merge(:display_name => display_name, :value => info_about_attr_value(value))
        end
      end.compact
      assembly_attrs + component_attrs
    end
    def info_about_attr_value(value)
      #TODO: handle complex attributes better 
      if value
        if value.kind_of?(Array)
          #value.map{|el|info_about_attr_value(el)}
          value.inspect
        elsif value.kind_of?(Hash)
          ret = Hash.new
          value.each do |k,v|
            ret[k] = info_about_attr_value(v)
          end
          ret
        elsif [String,Fixnum,TrueClass,FalseClass].find{|t|value.kind_of?(t)}
          value
        else
          value.inspect
        end
      end
    end
    private :get_attributes,:info_about_attr_value

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

    def get_nodes(*alt_cols)
      cols = ([:id,:display_name,:group_id] + alt_cols).uniq
      sp_hash = {
        :cols => cols,
        :filter => [:eq, :assembly_id, self[:id]]
      }
      Model.get_objs(model_handle.createMH(:node),sp_hash)
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
      service_module_name,template_name = AssemblyTemplate.parse_component_type(self[:component_type])
      end
      ui = self[:ui]
      node_idhs = get_nodes().map{|r|r.id_handle()}
      if node_idhs.empty?
        raise Error.new("Cannot find any nodes associated with assembly (#{self[:display_name]})")
      end
      Assembly.create_library_template(library_idh,node_idhs,template_name,service_module_name,ui)
    end
  end
end

