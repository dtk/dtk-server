# converts serialized form into object form
module DTK; class ServiceModule
  class AssemblyImport
    r8_nested_require('assembly_import','port_ref')
    r8_nested_require('assembly_import','port_mixin')
    include PortMixin
    extend FactoryObjectClassMixin
    def initialize(container_idh,module_branch,service_module,component_module_refs)
      @container_idh = container_idh
      @db_updates_assemblies = DBUpdateHash.new("component" => DBUpdateHash.new,"node" => DBUpdateHash.new)
      @ndx_ports = Hash.new
      @ndx_assembly_hashes = Hash.new #indexed by ref
      @module_branch = module_branch
      @module_name = service_module.module_name()
      @module_namespace = service_module.module_namespace()
      @service_module = service_module
      @component_module_refs = component_module_refs
      @ndx_version_proc_classes = Hash.new
      @ndx_assembly_file_paths = Hash.new
    end

    def process(module_name,hash_content,opts={})
      integer_version = determine_integer_version(hash_content,opts)
      version_proc_class = load_and_return_version_adapter_class(integer_version)
      version_proc_class.assembly_iterate(@service_module,hash_content) do |assemblies_hash,node_bindings_hash|
        aggregate_errors = ParsingError::Aggregate.new()
        assemblies_hash.each do |ref,assem|
          if file_path = opts[:file_path]
            @ndx_assembly_file_paths[ref] = file_path
          end
          aggregate_errors.aggregate_errors! do
            db_updates_cmp = version_proc_class.import_assembly_top(ref,assem,@module_branch,@module_name,opts)
            @db_updates_assemblies["component"].merge!(db_updates_cmp)

            # parse_node_bindings_hash! with opts below 
            # removes elements of node_bindings_hash that are not of form: {node => node_template}
            if db_updates_node_bindings = version_proc_class.parse_node_bindings_hash!(node_bindings_hash,:remove_non_legacy=> true)
              db_updates_cmp.values.first.merge!("node_bindings" => db_updates_node_bindings.mark_as_complete())
            end

            # if bad node reference, return error and continue with module import
            imported_nodes = version_proc_class.import_nodes(@container_idh,@module_branch,ref,assem,node_bindings_hash,@component_module_refs,opts)
            return imported_nodes if ParsingError.is_error?(imported_nodes)

            if workflow_hash = assem["workflow"]
              if parse_errors = Task::Template::ConfigComponents.find_parse_errors(workflow_hash)
                return parse_errors
              end
            end
            @db_updates_assemblies["node"].merge!(imported_nodes) 
            @ndx_assembly_hashes[ref] ||= assem
            @ndx_version_proc_classes[ref] ||= version_proc_class
          end
        end
        aggregate_errors.raise_error?()
      end
    end

    def import()
      module_branch_id = @module_branch[:id]
      mark_as_complete_cmp_constraint = {:module_branch_id=>module_branch_id} #so only delete extra components that belong to same module
      @db_updates_assemblies["component"].mark_as_complete(mark_as_complete_cmp_constraint)
      sp_hash = {
        :cols => [:id],
        :filter => [:eq,:module_branch_id, module_branch_id]
      }
      @existing_assembly_ids = Model.get_objs(@container_idh.createMH(:component),sp_hash).map{|r|r[:id]}
      mark_as_complete_node_constraint = {:assembly_id=>@existing_assembly_ids}
      @db_updates_assemblies["node"].mark_as_complete(mark_as_complete_node_constraint,:apply_recursively => true)

      Model.input_hash_content_into_model(@container_idh,@db_updates_assemblies)

      add_port_and_port_links()
      @db_updates_assemblies["component"]
    end

    def self.import_assembly_top(assembly_ref,assembly_hash,module_branch,module_name,opts={})
      if assembly_hash.empty?
        raise ParsingError.new("Empty assembly dsl file",opts_file_path(opts))
      end
      unless assembly_name = assembly_hash["name"]||opts[:default_assembly_name]
        raise ParsingError.new("No name associated with assembly dsl file",opts_file_path(opts))
      end

      {
        assembly_ref => {
          "display_name" => assembly_name,
          "type" => "composite",
          "module_branch_id" => module_branch[:id],
          "version" => module_branch.get_field?(:version),
          "component_type" => Assembly.ret_component_type(module_name,assembly_name),
          "attribute" => import_assembly_attributes(assembly_hash["attributes"],opts)
        }
      }
    end

    def self.import_nodes(container_idh,module_branch,assembly_ref,assembly_hash,node_bindings_hash,component_module_refs,opts={})
      # compute node_to_nb_rs and nb_rs_to_id
      node_to_nb_rs = ret_node_to_node_binding_rs(assembly_ref,node_bindings_hash)
      nb_rs_to_id = Hash.new
      unless node_to_nb_rs.empty?
        filter = [:oneof, :ref, node_to_nb_rs.values]
        nb_rs_containter = Library.get_public_library(container_idh.createMH(:library))
        nb_rs_to_id = nb_rs_containter.get_node_binding_rulesets(filter).inject(Hash.new) do |h,r|
          h.merge(r[:ref] => r[:id])
        end
      end

      aggregate_errors = ParsingError::Aggregate.new()
      unless nodes = assembly_hash["nodes"]
        return Hash.new
      end
      if nodes.kind_of?(Hash)
        # no op
      elsif nodes.kind_of?(String) # corner case: single node with no attributes
        nodes = {nodes => {}}
      else
        raise ParsingError.new("Nodes section is ill-formed",opts_file_path(opts))
      end
      ret = nodes.inject(Hash.new) do |h,(node_hash_ref,node_hash)|
        node_hash ||= Hash.new
        aggregate_errors.aggregate_errors!(h) do
          node_ref = assembly_template_node_ref(assembly_ref,node_hash_ref)
          type,attributes = import_type_and_node_attributes(node_hash,opts)
          node_output = {
            "display_name" => node_hash_ref, 
            "type" => type,
            "attribute" => attributes,
            "*assembly_id" => "/component/#{assembly_ref}"
          }
          if nb_rs = node_to_nb_rs[node_hash_ref]
            if nb_rs_id = nb_rs_to_id[nb_rs]
              node_output["node_binding_rs_id"] = nb_rs_id
            else
              # TODO: extend aggregate_errors.aggregate_errors to handle this
              # We want to import module still even if there are bad node references
              # we stop importing nodes when run into bad node reference but still continue with module import
              return ParsingError::BadNodeReference.new(:node_template => nb_rs,:assembly => assembly_hash["name"])
            end
          else
            node_output["node_binding_rs_id"] = nil
          end
 
          cmps_output = import_component_refs(container_idh,assembly_hash["name"],node_hash["components"],component_module_refs,opts)
          return cmps_output if ParsingError.is_error?(cmps_output)
          
            unless cmps_output.empty?
              node_output["component_ref"] = cmps_output
            end
          h.merge(node_ref => node_output)
        end
      end

      aggregate_errors.raise_error?()
      ret
    end

    def augmented_assembly_nodes()
      @augmented_assembly_nodes ||= @service_module.get_augmented_assembly_nodes()
    end

    def self.augment_with_parsed_port_names!(ports)
      ports.each do |p|
        p[:parsed_port_name] ||= Port.parse_port_display_name(p[:display_name])
      end
    end

   private
    def determine_integer_version(hash_content,opts={})
      if version = hash_content["dsl_version"]
        ServiceModule::DSLVersionInfo.version_to_integer_version(version,opts)
      elsif hash_content["assemblies"]
        1
      elsif hash_content["assembly"]
        2
      else
        ServiceModule::DSLVersionInfo.default_integer_version()
      end
    end

    def load_and_return_version_adapter_class(integer_version)
      self.class.load_and_return_version_adapter_class(integer_version)
    end
    def self.load_and_return_version_adapter_class(integer_version)
      return CachedAdapterClasses[integer_version] if CachedAdapterClasses[integer_version]
      adapter_name = "v#{integer_version.to_s}"
      opts = {
        :class_name => {:adapter_type => "AssemblyImport"},
        :subclass_adapter_name => true,
        :base_class => ServiceModule
      }
      CachedAdapterClasses[integer_version] = DynamicLoader.load_and_return_adapter_class("assembly_import",adapter_name,opts)
    end
    CachedAdapterClasses = Hash.new

    def self.parse_node_bindings_hash!(node_bindings_hash,opts={})      
      nil
    end

    def self.import_component_refs(container_idh,assembly_name,components_hash,component_module_refs,opts={})
      cmps_with_titles = Array.new

      unless components_hash
        return ParsingError::BadComponentReference.new("Missing components section",opts_file_path(opts))
      end
      components_hash = [components_hash] unless components_hash.kind_of?(Array)
      ret = components_hash.inject(Hash.new) do |h,cmp_input|
        parse = cmp_ref = nil
        begin
          parse = component_ref_parse(cmp_input)
          cmp_ref = Aux::hash_subset(parse,[:component_type,:version,:display_name])
          if cmp_ref[:version]
            cmp_ref[:has_override_version] = true
          end
          if cmp_title = parse[:component_title] 
            cmps_with_titles << {:cmp_ref => cmp_ref, :cmp_title => cmp_title}
          end
          
          ret_attribute_overrides(cmp_input).each_pair do |attr_name,attr_val|
            pntr = cmp_ref[:attribute_override] ||= Hash.new
            pntr.merge!(import_attribute_overrides(attr_name,attr_val))
          end
         rescue ParsingError => e
          return ParsingError.new(e.to_s,opts_file_path(opts))
        end
        h.merge(parse[:ref] => cmp_ref)
      end

      component_module_refs.set_matching_component_template_info?(ret.values, :donot_set_component_templates=>true)
      set_attribute_template_ids!(ret,container_idh)
      add_title_attribute_overrides!(cmps_with_titles,container_idh)
      ret
    end

    def self.component_ref_parse(cmp)
      ref,type,version = InternalForm.component_ref_type_and_version(cmp.kind_of?(Hash) ?  cmp.keys.first : cmp)
      ret = {:component_type => type, :ref => ref, :display_name => ref}
      ret.merge!(:version => version) if version
      ret
    end

    # These are attributes at the assembly level, as opposed to being at the component or node level
    def self.import_assembly_attributes(assembly_attrs_hash,opts={})
      assembly_attrs_hash ||= Hash.new
      unless assembly_attrs_hash.kind_of?(Hash)
        raise ParsingError.new("Assembly attribute(s) are ill-formed",opts_file_path(opts))
      end
      import_attributes_helper(assembly_attrs_hash)
    end

    # These are attributes at the node level
    # returns [type,attributes]
    def self.import_type_and_node_attributes(node_hash,opts={})
      type = Node::Type::Node.stub
      attributes = import_node_attributes(node_hash["attributes"],opts)
      if attr_type = attributes["type"]
        attributes.delete("type")
        type = Node::Type::NodeGroup.stub
      end
      [type,attributes]
    end
    def self.import_node_attributes(node_attrs_hash,opts={})
      node_attrs_hash ||= Hash.new
      unless node_attrs_hash.kind_of?(Hash)
        raise ParsingError.new("Node attribute(s) are ill-formed",opts_file_path(opts))
      end
      # TODO: make sure that each node attribute is legal
      import_attributes_helper(node_attrs_hash)
    end
    def self.import_attributes_helper(attr_val_hash)
      ret = DBUpdateHash.new()
      attr_val_hash.each_pair do |attr_name,attr_val|
        ref = dispaly_name = attr_name
        ret[ref] = {
          "display_name" => attr_name,
          "value_asserted" => attr_val,
          "data_type" => Attribute::Datatype.datatype_from_ruby_object(attr_val)
        }
      end
      ret.mark_as_complete()
    end

    def self.import_attribute_overrides(attr_name,attr_val,opts={})
      attr_info = {:display_name => attr_name, :attribute_value => attr_val}
      if opts[:cannot_change]
        attr_info.merge!(:cannot_change => true)
      end
      {attr_name => attr_info}
    end


    def self.set_attribute_template_ids!(cmp_refs,container_idh)
      ret = cmp_refs
      filter_disjuncts = Array.new
      ndx_attrs = Hash.new
      cmp_refs.each_value do |cmp_ref_info|
        if attrs = cmp_ref_info[:attribute_override]
          cmp_template_id = cmp_ref_info[:component_template_id]
          ndx_attrs[cmp_template_id] = {:attrs => attrs,:cmp_ref => cmp_ref_info}
          disjunct = [:and, [:eq, :component_component_id, cmp_template_id],
                      [:oneof, :display_name, attrs.keys]]
          filter_disjuncts << disjunct
        end
      end
      return ret if filter_disjuncts.empty?
      
      filter = (filter_disjuncts.size == 1 ? filter_disjuncts.first : ([:or] + filter_disjuncts))
      sp_hash = {
        :cols => [:id,:display_name,:component_component_id],
        :filter => filter
      }
      Model.get_objs(container_idh.createMH(:attribute),sp_hash).each do |r|
        cmp_template_id = r[:component_component_id]
        # relies on cmp_ref_info[:attribute_override] keys matching display_name
        if match = ndx_attrs[cmp_template_id][:attrs][r[:display_name]]
          match.merge!(:attribute_template_id => r[:id])
        end
      end
      
      # now check attributes not matched; 
      bad_attrs = Array.new
      ndx_attrs.each_value do |r|
        r[:attrs].each_pair do |ref,info|
          unless info[:attribute_template_id]
            bad_attrs << info.merge(:component_display_name => r[:cmp_ref][:display_name])
          end 
        end
      end
      unless bad_attrs.empty?
        # TODO: extend aggregate_errors.aggregate_errors to handle this
        bad_attrs_list = bad_attrs.map do |attr_info|
          cmp_name = Component.display_name_print_form(attr_info[:component_display_name])          
          "#{cmp_name}/#{attr_info[:display_name]}"
        end
        attribute = (bad_attrs.size == 1 ? "attribute" : "attributes")
        raise ErrorUsage.new("Bad #{attribute} (#{bad_attrs_list.join(', ')})")
      end
      ret
    end

    # cmps_with_titles is an array of hashes with keys :cmp_ref, :cmp_title
    def self.add_title_attribute_overrides!(cmps_with_titles,container_idh)
      return if cmps_with_titles.empty?
      cmp_mh = container_idh.createMH(:component)
      cmp_idhs = cmps_with_titles.map{|r|cmp_mh.createIDH(:id => r[:cmp_ref][:component_template_id])}
      ndx_title_attributes = Component::Template.get_title_attributes(cmp_idhs).inject(Hash.new) do |h,a|
        h.merge(a[:component_component_id] => a)
      end
      bad_attrs = Array.new
      cmps_with_titles.each do |r|
        cmp_ref = r[:cmp_ref]
        if title_attribute = ndx_title_attributes[cmp_ref[:component_template_id]]
          pntr = cmp_ref[:attribute_override] ||= Hash.new
          pntr.merge!(import_attribute_overrides(title_attribute[:display_name],r[:cmp_title],:cannot_change => true))
        else
          cmp_name = Component.display_name_print_form(cmp_ref[:display_name])
          # This should be caught when importing component module and is a component module, 
          # not a service module problem; so just logging as error here
          Log.error("Component module for #{cmp_name} missing the title field")
        end
      end
    end

    def self.opts_file_path(opts)
      (opts.kind_of?(Opts) ? opts :Opts.new(opts)).slice(:file_path)
    end
  end
end; end

