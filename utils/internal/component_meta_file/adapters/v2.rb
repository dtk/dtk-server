module DTK
  class ComponentMetaFileV2 < ComponentMetaFile
    def self.parse_check(input_hash)
      #TODO: stub
    end
    def self.normalize(input_hash)
      input_hash
    end
    def self.ret_migrate_processor(old_version_hash)
      MigrateProcessor.new(self,old_version_hash)
    end
    class MigrateProcessor
      def initialize(parent,old_version_hash)
        super()
        @old_version_hash = old_version_hash
        @parent = parent
      end
      def generate_new_version_hash()
        top = PrettyPrintHash.new
        top["version"] = @parent.version()
        @old_version_hash.inject(top) do |h,(cmp_ref,cmp_info)|
          h.merge(cmp_ref=>migrate(:component,cmp_ref,cmp_info))
        end
      end
      private
      AttrOrdered = { 
        :component =>
        [
         :description,
         {:external_ref => {:type => :external_ref}},
         :basic_type,
         {:ui => {:custom_fn => :ui}}
        ],
        :external_ref => 
        [
         :type
        ]
      }
      AttrOmit = {
        :component => %w{display_name component_type}
      }
      AttrProcessed = AttrOrdered.inject(Hash.new) do |h,(type,attrs_info)|
        proc_attrs = attrs_info.map do |attr_info|
          (attr_info.kind_of?(Hash) ? attr_info.keys.first.to_s : attr_info.to_s)
        end
        h.merge(type => proc_attrs)
      end
      TypesTreated = AttrOrdered.keys

      def raise_error_if_treated(type,ref,assigns)
        case type
          when :component
          unless ref == assigns["display_name"] and ref == assigns["component_type"]
            raise Error.new("assumption is that component (#{ref}), display_name (#{assigns["display_name"]}), and component_type (#{ref == assigns["component_type"]}) are all equal")
          end
        end
      end

      def migrate(type,ref,assigns)
        unless TypesTreated.include?(type)
          raise Error.new("Migration of type (#{type}) not yet treated")
        end
        ret = PrettyPrintHash.new
        raise_error_if_treated(type,ref,assigns)
        attr = migrate_type = custom_fn = has_ref = nil 
        AttrOrdered[type].each do |attr_assigns|
          if attr_assigns.kind_of?(Hash)  
            attr = attr_assigns.keys.first.to_s
            info = attr_assigns.values.first
            migrate_type,lambda_fn,has_ref = Aux::hash_subset(info,[:type,:custom_fn,:has_ref]) 
          else
            attr = attr_assigns.to_s
          end

          if val = assigns[attr]
            ref = nil
            if custom_fn
              val = send("migrate__#{custom_fn}".to_sym,val)
            else if migrate_type
              if has_ref
                ref = val.keys.first
                val = {ref => migrate(migrate_type,ref,val.keys.first)}
              else
                val = migrate(migrate_type,nil,val)
              end
            end
            ret[attr] = val
          end
        end
        rest_attrs = (assigns.keys - (AttrOmit[type]||[])) - AttrProcessed[type]
        rest_attrs.each do |attr|
          ret[attr] = assigns[attr] if assigns[attr]
        end
        ret
      end
    end
  end
end
