module XYZ
  module RestURI
    class << self
      def parse_factory_uri(factory_uri)
        if factory_uri =~ %r{(.*)/(.+)} 
          parent_uri = $1 == "" ? "/" : $1
          relation_type = $2.to_sym

	  raise Error.new("invalid relation type '#{relation_type.to_s}'") if DB_REL_DEF[relation_type].nil?
          [relation_type,parent_uri]
        else
	  raise Error.new("factory_uri (#{factory_uri}) in incorrect form")
        end
      end

      #TBD: for some or all these fns wil be useful to have a variant that deals with id_handles
      def parse_instance_uri(instance_uri)
        instance_uri =~ %r{(.*)/(.+)} ?
          #instance_ref,factory_uri
          [$2,$1] : nil
      end

      def ret_factory_uri(parent_uri,relation_type)
        parent_uri + "/" + relation_type.to_s
      end

      def ret_new_uri(factory_uri,ref,ref_num)
        qualified_ref = ref.to_s + (ref_num ? "-" + ref_num.to_s : "")
        ret_child_uri_from_qualified_ref(factory_uri,qualified_ref)
      end

      def ret_child_uri_from_qualified_ref(factory_uri,qualified_ref)
        factory_uri + "/" + qualified_ref.to_s
      end
    end
  end
end
