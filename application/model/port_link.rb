module DTK
  class PortLink < Model
    def self.common_columns()
      [:id,:group_id,:input_id,:output_id,:assembly_id,:temporal_order]
    end

    def self.check_valid_id(model_handle,id,opts={}) 
      if opts.empty?()
        check_valid_id_default(model_handle,id)
      elsif Aux.has_just_these_keys?(opts,[:assembly_idh])
        sp_hash = {
          :cols => [:id,:group_id,:assembly_id],
          :filter => [:eq,:id,id]
        }
        rows = get_objs(model_handle,sp_hash)
        unless port_link = rows.first
          raise ErrorIdInvalid.new(id,pp_object_type())
        end
        unless port_link[:assembly_id] == opts[:assembly_idh].get_id()
          raise ErrorUsage.new("Port with id (#{id.to_s}) does not belong to assembly")
        end
        id
      else
        raise Error.new("Unexpected options (#{opts.inspect})")
      end
    end

    def list_attribute_mappings()
      filter = [:eq,:port_link_id,id()]
      AttributeLink.get_augmented(model_handle(:attribute_link),filter).map do |al|
        {
          :input_attribute => al[:input].print_form(),
          :output_attribute => al[:output].print_form()
        }
      end
    end

    def self.create_port_and_attr_links(parent_idh,port_link_hash,opts={})
      #get the associated link_def_link TODO: if it does not exist means constraint violation
      link_def_link, components = get_link_def_and_components(parent_idh,port_link_hash)
      raise PortLinkError.new("Illegal link") unless link_def_link
      link_to_create = port_link_hash.merge(:temporal_order => link_def_link[:temporal_order])
      port_link = create_from_links_hash(parent_idh,[link_to_create],opts).first
      link_def_link.process(parent_idh,components,opts.merge(:port_link_idh => port_link.id_handle))
      port_link
    end

    #this sets temporal order if have option :set_port_link_temporal_order
    def create_attr_links!(parent_idh,opts={})
      update_obj!(:input_id,:output_id)
      #get the associated link_def_link TODO: if it does not exist means constraint violation
      link_def_link, components = self.class.get_link_def_and_components(parent_idh,self)
      raise PortLinkError.new("Illegal link") unless link_def_link
      if opts[:set_port_link_temporal_order] and link_def_link[:temporal_order]
        update(:temporal_order => link_def_link[:temporal_order])
      end
      link_def_link.process(parent_idh,components,:port_link_idh => id_handle())
      self
    end

    #TODO: possibly change to using refs w/o ids to make increemntal updates easier
    def self.ref_from_ids(input_id,output_id)
      "port_link:#{input_id}-#{output_id}"
    end
    def self.matches_ref_id_form(mh,input_output_rows)
      ret = Array.new
      return ret if input_output_rows.empty?
      sp_hash =  {
        :cols => [:id,:group_id,:input_id,:output_id],
        :filter => [:oneof,:ref,input_output_rows.map{|r|ref_from_ids(r[:input_id],r[:output_id])}]
      }
      get_objs(mh,sp_hash)
    end


   private
    def self.create_from_links_hash(parent_idh,links_to_create,opts={})
      parent_mn = parent_idh[:model_name]
      parent_id = parent_idh.get_id()
      port_link_mh = parent_idh.createMH(:model_name => :port_link,:parent_model_name => parent_mn)
      parent_col = DB.parent_field(parent_mn,:port_link)
      override_attrs = opts[:override_attrs]||{}
      rows = links_to_create.map do |link|
        {:input_id => link[:input_id],
         :output_id => link[:output_id],
          parent_col => parent_id,
          :ref => ref_from_ids(link[:input_id],link[:output_id])
        }.merge(override_attrs)
      end
      create_opts = {:returning_sql_cols => [:id,:input_id,:output_id]}
      #TODO: push in use of :c into create_from_rows
      create_from_rows(port_link_mh,rows,create_opts).map{|hash|new(hash,port_link_mh[:c])}
    end

    def self.get_link_def_and_components(parent_idh,port_link_hash)
      #returns [link_def_link,relevant_components]
      ret = [nil,nil]
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_type,:direction,:link_type,:link_def_info,:node_node_id],
        :filter => [:oneof, :id, [port_link_hash[:input_id],port_link_hash[:output_id]]]
      }
      link_def_info = get_objs(parent_idh.createMH(:port),sp_hash)
      #local_cmp_info will have a row per link_def_link associated with it (link_def_link under local link defs, not remote ones)
      local_cmp_info_and_links = link_def_info.select{|r|(r[:link_def]||{})[:local_or_remote] == "local"}
      return ret if local_cmp_info_and_links.empty?
      local_cmp_info = local_cmp_info_and_links.first #all elements wil agree on the parts aside from link_def_link

      remote_cmp_info = link_def_info.select{|r|r[:id] != local_cmp_info[:id]}
      if remote_cmp_info.empty?
        raise Error.new("Unexpected result that a remote port cannot be not found")
      end
      #local_cmp_info will have a row per link_def_link associated with it (link_def_link under local link defs, not remote ones)
      remote_cmp_info = remote_cmp_info.first

      return ret unless local_cmp_info[:link_type] == remote_cmp_info[:link_type]
      #find the matching link_def_link
      remote_cmp_type = remote_cmp_info[:component_type]

      #look for matching link
      components_coreside = (local_cmp_info[:node_node_id] == remote_cmp_info[:node_node_id])
      match = local_cmp_info_and_links.find do |r|
        possible_link = r[:link_def_link]||{}
        if possible_link[:remote_component_type] == remote_cmp_type 
          if components_coreside
            possible_link[:type] == "internal"
          else
            possible_link[:type] == "external"
          end
        end
      end
      return ret unless match

      #get remote component
      remote_cmp_display_name = remote_cmp_info[:display_name]
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:node_node_id,:component_type,:implementation_id,:extended_base],
        :filter => [:and,[:eq,:display_name,remote_cmp_display_name],[:eq,:node_node_id,remote_cmp_info[:node_node_id]]]
      }
      cmp_mh = local_cmp_info[:component].model_handle()
      rows = Model.get_objs(cmp_mh,sp_hash)
      unless rows.size == 1
      #TODO: refine if multiple of same component types
        raise Error.new("Unexpected that getting remote port link component does not return unique element")
      else
        remote_cmp = rows.first
      end
      link_def_link = match[:link_def_link].merge!(:local_component_type => local_cmp_info[:component][:component_type])
      relevant_components = [local_cmp_info[:component], remote_cmp]
      [link_def_link,relevant_components]
    end
  end

  class PortLinkError < ErrorUsage
  end
end
