#converts serialized form into object form
module DTK; class ServiceModule
  class AssemblyImport
    r8_nested_require('assembly_import','port')
    include PortMixin
    def initialize(container_idh,module_branch,module_name,module_version_constraints)
      @container_idh = container_idh
      @db_updates_assemblies = DBUpdateHash.new("component" => DBUpdateHash.new,"node" => DBUpdateHash.new)
      @ndx_ports = Hash.new
      @ndx_assembly_hashes = Hash.new #indexed by ref
      @module_branch = module_branch
      @module_name = module_name
      @service_module = get_service_module(container_idh,module_name)
      @module_version_constraints = module_version_constraints
    end

    def process(module_name,hash_content)
      #TODO: initially determing from syntax what version it is; this wil be replaced by explicit versions at the service or assembly level
      integer_version = determine_integer_version(hash_content)
      @version_proc_class = load_and_return_version_adapter_class(integer_version)
      @version_proc_class.assembly_iterate(module_name,hash_content) do |assemblies_hash,node_bindings_hash|
        dangling_errors = ErrorUsage::DanglingComponentRefs::Aggregate.new()
        assemblies_hash.each do |ref,assem|
          dangling_errors.aggregate_errors! do
            @db_updates_assemblies["component"].merge!(@version_proc_class.import_assembly_top(ref,assem,@module_branch,@module_name))
            @db_updates_assemblies["node"].merge!(@version_proc_class.import_nodes(@container_idh,@module_branch,ref,assem,node_bindings_hash,@module_version_constraints))
            @ndx_assembly_hashes[ref] ||= assem
          end
        end
        dangling_errors.raise_error?()
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
    end

    def self.import_assembly_top(serialized_assembly_ref,assembly_hash,module_branch,module_name)
      version_field = module_branch.get_field?(:version)
      assembly_ref = internal_assembly_ref__with_version(serialized_assembly_ref,version_field)
      {
        assembly_ref => {
          "display_name" => assembly_hash["name"], 
          "type" => "composite",
          "module_branch_id" => module_branch[:id],
          "version" => version_field,
          "component_type" => Assembly.ret_component_type(module_name,assembly_hash["name"])
        }
      }
    end

    def self.import_nodes(container_idh,module_branch,assembly_ref,assembly_hash,node_bindings_hash,version_constraints)
      #compute node_to_nb_rs and nb_rs_to_id
      node_to_nb_rs = ret_node_to_node_binding_rs(assembly_ref,node_bindings_hash)
      nb_rs_to_id = Hash.new
      unless node_to_nb_rs.empty?
        filter = [:oneof, :ref, node_to_nb_rs.values]
        #TODO: hard coded that nodding in public library
        nb_rs_containter = Library.get_public_library(container_idh.createMH(:library))
        nb_rs_to_id = nb_rs_containter.get_node_binding_rulesets(filter).inject(Hash.new) do |h,r|
          h.merge(r[:ref] => r[:id])
        end
      end

      dangling_errors = ErrorUsage::DanglingComponentRefs::Aggregate.new()
      version_field = module_branch.get_field?(:version)
      assembly_ref_with_version = internal_assembly_ref__add_version(assembly_ref,version_field)
      ret = assembly_hash["nodes"].inject(Hash.new) do |h,(node_hash_ref,node_hash)|
        dangling_errors.aggregate_errors!(h) do
          node_ref = "#{assembly_ref_with_version}--#{node_hash_ref}"
          node_output = {
            "display_name" => node_hash_ref, 
            "type" => "stub",
            "*assembly_id" => "/component/#{assembly_ref_with_version}" 
          }
          if nb_rs = node_to_nb_rs[node_hash_ref]
            if nb_rs_id = nb_rs_to_id[nb_rs]
              node_output["node_binding_rs_id"] = nb_rs_id
            else
              #TODO: extend dangling_errors.aggregate_errors to handle this
              raise ErrorUsage.new("Bad node reference #{nb_rs})")
            end
          else
            node_output["node_binding_rs_id"] = nil
          end
          cmps_output = import_component_refs(container_idh,assembly_hash["name"],node_hash["components"],version_constraints)
          unless cmps_output.empty?
            node_output["component_ref"] = cmps_output
          end
          h.merge(node_ref => node_output)
        end
      end
      dangling_errors.raise_error?()
      ret
    end

    def self.import_assembly_top(serialized_assembly_ref,assembly_hash,module_branch,module_name)
      version_field = module_branch.get_field?(:version)
      assembly_ref = internal_assembly_ref__with_version(serialized_assembly_ref,version_field)
      {
        assembly_ref => {
          "display_name" => assembly_hash["name"], 
          "type" => "composite",
          "module_branch_id" => module_branch[:id],
          "version" => version_field,
          "component_type" => Assembly.ret_component_type(module_name,assembly_hash["name"])
        }
      }
    end

    def self.import_nodes(container_idh,module_branch,assembly_ref,assembly_hash,node_bindings_hash,version_constraints)
      #compute node_to_nb_rs and nb_rs_to_id
      node_to_nb_rs = ret_node_to_node_binding_rs(assembly_ref,node_bindings_hash)
      nb_rs_to_id = Hash.new
      unless node_to_nb_rs.empty?
        filter = [:oneof, :ref, node_to_nb_rs.values]
        #TODO: hard coded that nodding in public library
        nb_rs_containter = Library.get_public_library(container_idh.createMH(:library))
        nb_rs_to_id = nb_rs_containter.get_node_binding_rulesets(filter).inject(Hash.new) do |h,r|
          h.merge(r[:ref] => r[:id])
        end
      end

      dangling_errors = ErrorUsage::DanglingComponentRefs::Aggregate.new()
      version_field = module_branch.get_field?(:version)
      assembly_ref_with_version = internal_assembly_ref__add_version(assembly_ref,version_field)
      ret = assembly_hash["nodes"].inject(Hash.new) do |h,(node_hash_ref,node_hash)|
        dangling_errors.aggregate_errors!(h) do
          node_ref = "#{assembly_ref_with_version}--#{node_hash_ref}"
          node_output = {
            "display_name" => node_hash_ref, 
            "type" => "stub",
            "*assembly_id" => "/component/#{assembly_ref_with_version}" 
          }
          if nb_rs = node_to_nb_rs[node_hash_ref]
            if nb_rs_id = nb_rs_to_id[nb_rs]
              node_output["node_binding_rs_id"] = nb_rs_id
            else
              #TODO: extend dangling_errors.aggregate_errors to handle this
              raise ErrorUsage.new("Bad node reference #{nb_rs})")
            end
          else
            node_output["node_binding_rs_id"] = nil
          end
          cmps_output = import_component_refs(container_idh,assembly_hash["name"],node_hash["components"],version_constraints)
          unless cmps_output.empty?
            node_output["component_ref"] = cmps_output
          end
          h.merge(node_ref => node_output)
        end
      end
      dangling_errors.raise_error?()
      ret
    end

    def augmented_assembly_nodes()
      @augmented_assembly_nodes ||= @service_module.get_augmented_assembly_nodes()
    end

    def self.augment_with_parsed_port_names!(ports)
      ports.each do |p|
        p[:parsed_port_name] ||= Port.parse_external_port_display_name(p[:display_name])
      end
    end

    def self.internal_assembly_ref__add_version(assembly_ref,version_field)
      Assembly.internal_assembly_ref__add_version(assembly_ref,version_field)
    end

   private
    def determine_integer_version(hash_content)
      if hash_content["assemblies"]
        1
      elsif hash_content["assembly"]
        2
      else
        raise Error.new("Cannot determine assembly dsl version")
      end
    end

    def load_and_return_version_adapter_class(integer_version)
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
      
    def get_service_module(container_idh,module_name)
      container_idh.create_object().get_service_module(module_name)
    end

    def self.internal_assembly_ref__with_version(serialized_assembly_ref,version_field)
      module_name,assembly_name = parse_serialized_assembly_ref(serialized_assembly_ref)
      Assembly.internal_assembly_ref(module_name,assembly_name,version_field)
    end

    #return [module_name,assembly_name]
    def self.parse_serialized_assembly_ref(ref)
      if ref =~ /(^.+)::(.+$)/
        [$1,$2]
      elsif ref =~ /(^[^-]+)-(.+$)/ #TODO: this can be eventually deprecated
        [$1,$2]
      else
        raise Error.new("Unexpected form for serialized assembly ref (#{ref})")
      end
    end

    def self.import_component_refs(container_idh,assembly_name,components_hash,version_constraints)
      ret = components_hash.inject(Hash.new) do |h,cmp_input|
        parse = component_ref_parse(cmp_input)
        cmp_ref = Aux::hash_subset(parse,[:component_type,:version,:display_name])
        if cmp_ref[:version]
          cmp_ref[:has_override_version] = true
        end
        ret_attribute_overrides(cmp_input).each_pair do |attr_name,attr_val|
          pntr = cmp_ref[:attribute_override] ||= Hash.new
          pntr.merge!(import_attribute_overrides(attr_name,attr_val))
        end
        h.merge(parse[:ref] => cmp_ref)
      end
      #find and insert component template ids in first component_refs and then for the attribute_overrides
      #just set component_template_id
      version_constraints.set_matching_component_template_info!(ret.values, :donot_set_component_templates=>true)
      set_attribute_template_ids!(container_idh,ret)
      ret
    end

    def self.component_ref_parse(cmp)
      term = (cmp.kind_of?(Hash) ?  cmp.keys.first : cmp).gsub(Regexp.new(Seperators[:module_component]),"__")
      if term =~ Regexp.new("(^.+)#{Seperators[:component_version]}(.+$)")
        type = $1; version = $2
      else
        type = term; version = nil
      end
      ret = {:component_type => type, :ref => term, :display_name => term}
      ret.merge!(:version => version) if version
      ret
    end

    def self.import_attribute_overrides(attr_name,attr_val)
      {attr_name => {:display_name => attr_name, :attribute_value => attr_val}}
    end

    def self.set_attribute_template_ids!(container_idh,cmp_ref)

      cmp_ref_info = cmp_ref.values.first
      if attrs = cmp_ref_info[:attribute_override]
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:and,[:component_component_id,cmp_ref_info[:component_template_id]],
                      [:oneof, :display_name,attrs.keys]]
        }
        attr_mh = container_idh.createMH(:attribute)
        Model.get_objs(attr_mh,sp_hash).each do |r|
          #relies on cmp_ref_info[:attribute_override] keys matching display_name
          attrs[r[:display_name]].merge!(:attribute_template_id => r[:id])
        end

        bad_attrs = attrs.reject{|ref,info|info[:attribute_template_id]}
        unless bad_attrs.empty?
          #TODO: extend dangling_errors.aggregate_errors to handle this
          bad_attrs_list = bad_attrs.keys.join(",")
          attribute = (bad_attrs.size == 1 ? "attribute" : "attributes")
          cmp_ref_name = cmp_ref_info[:component_type].gsub(/__/,"::")
          raise ErrorUsage.new("Bad #{attribute} (#{bad_attrs_list}) on component ref (#{cmp_ref_name})")
        end
      end
      cmp_ref
    end

  end
end; end

