module DTK
  class ModuleRefs
    class Parse < self
      def self.update_from_dsl_parsed_info(branch,parsed_info)
        content_hash_content = reify_content(branch.model_handle(:model_ref),parsed_info)
        update(branch,content_hash_content)
        ModuleRefs.new(branch,content_hash_content,:content_hash_form_is_reified => true)
      end

     private
      def self.reify_content(mh,object)
        # if Hash type then this comes from querying the model ref table
        if object.kind_of?(Hash)
          object.inject(Hash.new) do |h,(k,v)|
            if v.kind_of?(ModuleRef)
              h.merge(k.to_sym => ModuleRef.reify(mh,v))
            else
              raise Error.new("Unexpected value associated with component module ref: #{v.inspect}")
            end
          end
          #This comes from parsing the dsl file
        elsif object.kind_of?(ServiceModule::DSLParser::Output)
          object.inject(Hash.new) do |h,r|
            internal_form = convert_parse_to_internal_form(r)
            h.merge(parse_form_module_name(r).to_sym => ModuleRef.reify(mh,internal_form))
          end
        else
          raise Error.new("Unexpected input (#{object.class})")
        end
      end

      def self.parse_form_module_name(parse_form_hash)
        parse_form_hash[:component_module]
      end
      def self.convert_parse_to_internal_form(parse_form_hash)
        ret = {
          :module_name => parse_form_hash[:component_module],
          :module_type => 'component'
        }
        # TODO: should have dtk common return namespace_info instead of remote_namespace
        if namespace_info = parse_form_hash[:remote_namespace]
          ret[:namespace_info] = namespace_info
        end
        if version_info = parse_form_hash[:version_info]
          ret[:version_info] = version_info
        end
        ret
      end
    end
  end
end