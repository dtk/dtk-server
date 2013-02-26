module DTK; class ServiceModule
  class AssemblyImport
    class V2 < self
      def self.assembly_iterate(module_name,hash_content,&block)
        name = hash_content["name"]
        assemblies_hash = {ServiceModule.assembly_ref(module_name,name) => hash_content["assembly"].merge("name" => name)}
        node_bindings_hash = hash_content["node_bindings"]
        block.call(assemblies_hash,node_bindings_hash)
      end

     private
      include AssemblyImportExportCommon

      def self.ret_node_to_node_binding_rs(assembly_ref,node_bindings_hash)
        (node_bindings_hash||{}).inject(Hash.new) do |h,(node,v)|
          merge_hash = 
            if v.kind_of?(String) then {node => v}
            elsif v.kind_of?(Hash)
              Log.error("Not implemented yet have node bindings with explicit properties")
              Hash.new
            else
              raise Error.new("Unexpected form of node binding")
            end
          h.merge(merge_hash)
        end
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

      def self.internal_assembly_ref__with_version(serialized_assembly_ref,version_field)
        module_name,assembly_name = parse_serialized_assembly_ref(serialized_assembly_ref)
        Assembly.internal_assembly_ref(module_name,assembly_name,version_field)
      end
      class << self
       public
        def internal_assembly_ref__add_version(assembly_ref,version_field)
          Assembly.internal_assembly_ref__add_version(assembly_ref,version_field)
        end
      end

      def self.import_component_refs(container_idh,assembly_name,components_hash,version_constraints)
        ret = components_hash.inject(Hash.new) do |h,cmp_hash|
          parse = component_ref_parse(cmp_hash)
          cmp_ref = Aux::hash_subset(parse,[:component_type,:version,:display_name])
          if cmp_ref[:version]
            cmp_ref[:has_override_version] = true
          end
          h.merge(parse[:ref] => cmp_ref)
        end
        #find and insert component template ids
        #just set component_template_id
        version_constraints.set_matching_component_template_info!(ret.values, :donot_set_component_templates=>true)
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

      def self.attribute_overrides(cmp,cmp_template_relative_uri)
        ret = Hash.new
        return ret unless cmp.kind_of?(Hash)
        cmp.values.first.inject(Hash.new) do |h,(name,value)|
          attr_template_id = "#{cmp_template_relative_uri}/attribute/#{name}"
          h.merge(name => {"display_name" => name, "attribute_value" => value, "*attribute_template_id" => attr_template_id}) 
        end       
      end

    end
  end
end; end
