r8_require('../../factory_object_type')
module DTK
  class Assembly; class Template
    class Factory < self
      extend FactoryObjectClassMixin
      include FactoryObjectMixin

      def self.get_or_create_service_module(project,service_module_name,opts={})
        sp_hash = {
          :cols => [:id,:group_id,:display_name],
          :filter => [:eq,:display_name,service_module_name]
        }
        if service_module = get_obj(project.model_handle(:service_module),sp_hash)
          service_module
        else
          if opts[:mode] == :update
            raise ErrorUsage.new("Service module (#{service_module_name}) does not exist")
          end
          opts_create = {:config_agent_type => ConfigAgentType}
          module_and_branch_info = ServiceModule.create_module(project,service_module_name,opts_create)
          module_and_branch_info[:module_idh].create_object()
        end
      end
      ConfigAgentType = :puppet #TODO: stub

      # creates a new assembly template if it does not exist
      def self.create_or_update_from_instance(assembly_instance,service_module,assembly_name,opts={})
        assembly_factory = create_assembly_factory(assembly_instance,service_module,assembly_name,opts)
        assembly_factory.create_assembly_template()
      end

      def create_assembly_template()
        add_content_for_clone!()
        create_assembly_template_aux()
      end

      def set_attrs!(project_idh,assembly_instance,service_module_branch)
        @project_idh = project_idh
        @assembly_instance = assembly_instance 
        @service_module_branch = service_module_branch
        self
      end

     private
      def self.create_assembly_factory(assembly_instance,service_module,assembly_name,opts={})
        service_module_name = service_module.get_field?(:display_name)
        local_params = ModuleBranch::Location::LocalParams::Server.new(
          :module_type => :service_module,
          :module_name => service_module_name,
          :namespace => service_module.module_namespace(),
          :version => opts[:version]
        )
        service_module_branch = service_module.get_module_branch_from_local_params(local_params)
        project_idh = service_module.get_project().id_handle()

        assembly_mh = project_idh.create_childMH(:component)
        if ret = exists?(assembly_mh,project_idh,service_module_name,assembly_name)
          if opts[:mode] == :create
            raise ErrorUsage.new("Assembly (#{assembly_name}) already exists in service module (#{service_module_name})")
          end
          ret.set_attrs!(project_idh,assembly_instance,service_module_branch)
        else
          if opts[:mode] == :update
            raise ErrorUsage.new("Assembly (#{assembly_name}) does not exist in service module (#{service_module_name})")
          end
          assembly_mh = project_idh.create_childMH(:component)
          hash_values = {
            :project_project_id => project_idh.get_id(),
            :ref => service_module.assembly_ref(assembly_name),
            :display_name => assembly_name,
            :type => "composite",
            :module_branch_id => service_module_branch[:id],
            :component_type => Assembly.ret_component_type(service_module_name,assembly_name)
          }
          ret = create(assembly_mh,hash_values)
          ret.set_attrs!(project_idh,assembly_instance,service_module_branch)
        end
      end

      attr_reader :assembly_instance,:project_idh,:service_module_branch

      def project_uri()
        @project_uri ||= @project_idh.get_uri()
      end

      def add_content_for_clone!()
        node_idhs = assembly_instance.get_nodes().map{|r|r.id_handle()}
        if node_idhs.empty?
          raise ErrorUsage.new("Cannot find any nodes associated with assembly (#{assembly_instance.get_field?(:display_name)})")
        end

        # 1) get a content object, 2) modify, and 3) persist
        port_links,dangling_links = Node.get_conn_port_links(node_idhs)
        # TODO: raise error to user if dangling link
        Log.error("dangling links #{dangling_links.inspect}") unless dangling_links.empty?

        task_templates = Task::Template::ConfigComponents.get_existing_or_stub_templates(:assembly,assembly_instance)

        node_scalar_cols = FactoryObject::CommonCols + [:node_binding_rs_id]
        node_mh = node_idhs.first.createMH()
        node_ids = node_idhs.map{|idh|idh.get_id()}

        # get assembly-level attributes
        assembly_level_attrs = assembly_instance.get_assembly_level_attributes().reject do |a|
          a[:attribute_value].nil?
        end

        # get node-level attributes
        ndx_node_level_attrs = Hash.new
        Node.get_node_level_assembly_template_attributes(node_idhs).each do |r|
          (ndx_node_level_attrs[r[:node_node_id]] ||= Array.new) << r
        end

        # get contained ports
        sp_hash = {
          :cols => [:id,:display_name,:ports_for_clone],
          :filter => [:oneof,:id,node_ids]
        }
        @ndx_ports = Hash.new
        node_port_mapping = Hash.new
        Model.get_objs(node_mh,sp_hash,:keep_ref_cols => true).each do |r|
          port = r[:port].merge(:link_def => r[:link_def])
          (node_port_mapping[r[:id]] ||= Array.new) << port
          @ndx_ports[port[:id]] = port
        end

        # get contained components-non-default attributes
        sp_hash = {
          :cols => node_scalar_cols + [:cmps_and_non_default_attrs],
          :filter => [:oneof,:id,node_ids]
        }

        node_cmp_attr_rows = Model.get_objs(node_mh,sp_hash,:keep_ref_cols => true)
        if node_cmp_attr_rows.empty?
          raise ErrorUsage.new("No components in the nodes being grouped to be an assembly template")
        end
        cmp_scalar_cols = node_cmp_attr_rows.first[:component].keys - [:non_default_attribute]
        @ndx_nodes = Hash.new
        node_cmp_attr_rows.each do |r|
          node_id = r[:id]
          @ndx_nodes[node_id] ||= 
            r.hash_subset(*node_scalar_cols).merge(
              :components => Array.new,
              :ports => node_port_mapping[node_id],
              :attributes=>ndx_node_level_attrs[node_id]
            )
          cmps = @ndx_nodes[node_id][:components]
          cmp_id = r[:component][:id]
          unless matching_cmp = cmps.find{|cmp|cmp[:id] == cmp_id}
            matching_cmp = r[:component].hash_subset(*cmp_scalar_cols).merge(:non_default_attributes => Array.new)
            cmps << matching_cmp
          end
          if attr = r[:non_default_attribute]
            unless attr[:attribute_value].nil?
              matching_cmp[:non_default_attributes] << attr
            end
          end
        end
        update_hash = {
          :nodes => @ndx_nodes.values, 
          :port_links => port_links, 
          :assembly_level_attributes => assembly_level_attrs
        }
        merge!(update_hash)
        merge!(:task_templates => task_templates) unless task_templates.empty?
        self
      end

      # TODO: can collapse above and below; aboves looks like extra intermediate level
      def create_assembly_template_aux()
        nodes = self[:nodes].inject(DBUpdateHash.new){|h,node|h.merge(create_node_content(node))}
        port_links = self[:port_links].inject(DBUpdateHash.new){|h,pl|h.merge(create_port_link_content(pl))}
        # Need to explicitly prune because the port link refs used when creating from import uses ids
        prune_duplicate_port_links!(port_links) 
        task_templates = self[:task_templates].inject(DBUpdateHash.new){|h,tt|h.merge(create_task_template_content(tt))}
        assembly_level_attributes = self[:assembly_level_attributes].inject(DBUpdateHash.new){|h,a|h.merge(create_assembly_level_attributes(a))}

        # only need to mark as complete if assembly template exists already
        if assembly_template_idh = id_handle_if_object_exists?()
          assembly_template_id = assembly_template_idh.get_id()
          nodes.mark_as_complete({:assembly_id=>assembly_template_id},:apply_recursively => true)
          port_links.mark_as_complete(:assembly_id=>assembly_template_id)
          task_templates.mark_as_complete(:component_component_id=>assembly_template_id)
          assembly_level_attributes.mark_as_complete(:component_component_id=>assembly_template_id)
        end

        @template_output = ServiceModule::AssemblyExport.create(project_idh,service_module_branch)
        assembly_ref = self[:ref]
        assembly_hash = hash_subset(:display_name,:type,:ui,:module_branch_id,:component_type)
        assembly_hash.merge!(:task_template => task_templates) unless task_templates.empty?
        assembly_hash.merge!(:attribute => assembly_level_attributes) unless assembly_level_attributes.empty?
        @template_output.merge!(:node => nodes,:port_link => port_links,:component => {assembly_ref => assembly_hash})
        Transaction do 
          @template_output.save_to_model()
          @template_output.serialize_and_save_to_repo()
        end
      end

      def self.exists?(assembly_mh,project_idh,service_module_name,template_name)
        props = {
          :service_module_name => service_module_name,
          :template_name => template_name,
          :project_idh => project_idh
        }
        if assembly_template = Template.get_from(assembly_mh,props,:cols => ExistsTemplateCols)
          subclass_model(assembly_template) #so that what is returned is object of type Assembly::Template::Factory
        end
      end
      ExistsTemplateCols = [:id,:display_name,:group_id,:component_type,:project_project_id,:ref,:ui,:type,:module_branch_id]

      def create_port_link_content(port_link)
        in_port = @ndx_ports[port_link[:input_id]]
        in_node_ref = node_ref(@ndx_nodes[in_port[:node_node_id]])
        in_port_ref = qualified_ref(in_port)
        out_port = @ndx_ports[port_link[:output_id]]
        out_node_ref = node_ref(@ndx_nodes[out_port[:node_node_id]])
        out_port_ref = qualified_ref(out_port)

        assembly_ref = self[:ref]
        port_link_ref = "#{assembly_ref}--#{in_node_ref}-#{in_port_ref}--#{out_node_ref}-#{out_port_ref}"
        port_link_hash = {
          "*input_id" => "/node/#{in_node_ref}/port/#{in_port_ref}",
          "*output_id" => "/node/#{out_node_ref}/port/#{out_port_ref}",
          "*assembly_id" => "/component/#{assembly_ref}"
        }
        {port_link_ref => port_link_hash}
      end

      def prune_duplicate_port_links!(port_links)
        return port_links if port_links.empty?()
        relative_port_refs = port_links.values.map{|pl|[pl["*input_id"],pl["*output_id"]]}.flatten(1)
        port_matches = get_ndx_target_port_refs(relative_port_refs)
        return port_links if port_matches.empty?

        pl_to_match = Array.new
        prune_duplicate_port_links_iter(port_matches,port_links) do |ref,input_match_id,output_match_id|
          pl_to_match << {:input_id => input_match_id, :output_id => output_match_id}
        end

        pl_matches = PortLink.matches_ref_id_form(model_handle(:port_link),pl_to_match)
        return port_links if pl_matches.empty?

        prune_duplicate_port_links_iter(port_matches,port_links) do |ref,input_match_id,output_match_id|
          if pl_matches.find{|pl_match| input_match_id == pl_match[:input_id] and output_match_id == pl_match[:output_id]}
            port_links.delete(ref)
          end
        end
        port_links
      end

      def prune_duplicate_port_links_iter(port_matches,port_links,&block)
        port_links.each_pair do |ref,pl_info|
          if input_match_id = port_matches[pl_info["*input_id"]]
            if output_match_id = port_matches[pl_info["*output_id"]]
              block.call(ref,input_match_id,output_match_id)
            end
          end
        end
      end

      def get_ndx_target_port_refs(relative_port_refs_x)
        relative_port_refs = relative_port_refs_x.map{|pr|pr.gsub(/^\//,'')}
        IDInfoTable.get_ndx_ids_matching_relative_uris(@project_idh,project_uri(),relative_port_refs).inject(Hash.new) do |h,(k,v)|
          h.merge("/#{k}" => v)
        end
      end

      def create_task_template_content(task_template)
        ref,create_hash = Task::Template.ref_and_create_hash(task_template[:content],task_template[:task_action])
        {ref => create_hash}
      end

      def create_assembly_level_attributes(attr)
        ref = display_name = attr[:display_name]
        create_hash = {
          :display_name => display_name,
          :value_asserted => attr[:attribute_value],
          :data_type => attr[:data_type]||AttributeDatatype.default()
        }
        {ref => create_hash}
      end

      def create_node_content(node)
        node_ref = node_ref(node)
        cmp_refs = node[:components].inject(Hash.new){|h,cmp|h.merge(create_component_ref_content(cmp))}
        ports = (node[:ports]||[]).inject(Hash.new){|h,p|h.merge(create_port_content(p))}
        node_attrs = (node[:attributes]||[]).inject(Hash.new){|h,a|h.merge(create_node_attribute_content(a))}
        node_hash = Aux::hash_subset(node,[:display_name,:node_binding_rs_id])
        node_hash.merge!(
          "*assembly_id" => "/component/#{self[:ref]}",
          :type => Node::Type::Node.stub,
          :component_ref => cmp_refs, 
          :port => ports,
          :attribute => node_attrs
        )
        {node_ref => node_hash}
      end

      def create_port_content(port)
        port_ref = qualified_ref(port)
        port_hash = Aux::hash_subset(port,[:display_name,:description,:type,:direction,:link_type,:component_type])
        port_hash.merge!(:link_def_id => port[:link_def][:ancestor_id]) if port[:link_def]
        {port_ref => port_hash}
      end

      def create_node_attribute_content(attr)
        attr_ref = attr[:display_name]
        attr_hash = Aux::hash_subset(attr,[:display_name,:value_asserted,:value_derived])
        {attr_ref => attr_hash}
      end

      def create_component_ref_content(cmp)
        cmp_ref_ref = qualified_ref(cmp)
        cmp_ref_hash = Aux::hash_subset(cmp,[:display_name,:description,:component_type])
        cmp_template_id = cmp[:ancestor_id]
        cmp_ref_hash.merge!(:component_template_id => cmp_template_id)
        add_attribute_overrides!(cmp_ref_hash,cmp,cmp_template_id)
        {cmp_ref_ref => cmp_ref_hash}
      end

      def node_ref(node)
        assembly_template_node_ref(self[:ref],node[:display_name])
      end

      def add_attribute_overrides!(cmp_ref_hash,cmp,cmp_template_id)
        attrs = cmp[:non_default_attributes]
        return if attrs.nil? or attrs.empty?
        sp_hash = {
          :cols => [:id,:display_name,:data_type,:semantic_data_type],
          :filter => [:and,[:eq,:component_component_id,cmp_template_id],[:oneof,:display_name,attrs.map{|a|a[:display_name]}]]
        }
        ndx_attrs = Model.get_objs(model_handle(:attribute),sp_hash).inject(Hash.new) do |h,r|
          h.merge(r[:display_name] => r)
        end
        attr_override = cmp_ref_hash[:attribute_override] = Hash.new
        attrs.each do |attr|
          attr_ref =  attr[:ref]
          attr_hash =  AttrHash.new(attr,cmp)
          if attribute_template = ndx_attrs[attr[:display_name]] 
            attr_hash[:attribute_template_id] = attribute_template[:id]
            attr_hash.merge!(Aux::hash_subset(attribute_template,[:data_type,:semantic_data_type]))
          else
            component_type = Component.display_name_print_form(cmp_ref_hash[:component_type])
            module_name = Component.module_name(cmp_ref_hash[:component_type])
            raise ErrorUsage.new("Attribute (#{attr[:display_name]}) does not exist in base component (#{component_type}); you may need to invoke push-module-updates #{module_name}")
          end
          attr_override[attr_ref] = attr_hash
        end
      end
      class AttrHash < ::Hash
        attr_reader :is_title_attribute
        def initialize(attr,cmp)
          super()
          replace(Aux::hash_subset(attr,[:display_name,:description]))
          self[:attribute_value] = attr[:attribute_value] # virtual attributes do not work in Aux::hash_subset
          @is_title_attribute = ((not cmp[:only_one_per_node]) and attr.is_title_attribute?())
        end
      end
    end
  end; end
end
