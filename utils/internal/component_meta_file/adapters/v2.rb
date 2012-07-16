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
         {:external_ref => {:method => :migrate_external_ref}},
         :basic_type,
         :ui
        ]
      }
      AttrProcessed = AttrOrdered.inject(Hash.new) do |h,(type,attrs_info)|
        proc_attrs = attrs_info.map do |attr_info|
          (attr_info.kind_of?(Hash) ? attr_info.keys.first.to_s : attr_info.to_s)
        end
        h.merge(type => proc_attrs)
      end
      TypesTreated = AttrOrdered.keys
      AttrOmit = {
        :component => %w{display_name component_type}
      }

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
        AttrOrdered[type].each do |attr_assigns|
          attr,migrate_type, has_ref = 
            (attr_assigns.kind_of?(Hash) ? 
             [attr_assigns.keys.first.to_s,attr_assigns.values.first[:method],attr_assigns.values.first[:has_ref]] : 
             [attr_assigns.to_s,nil,nil])
          if val = assigns[attr]
            ref = nil
            if migrate_type
              if has_ref
                ref = val.keys.first
                val = {ref => migrate(migrate_type,ref,val.keys.first)}
              else
                val = migrate(migrate_type,nil,val.keys.first)
              end
            end
          end
        end
        rest_attrs = (assigns.keys - AttrOmit[type]) - AttrProcessed[type]
        rest_attrs.each do |attr|
          ret[attr] = assigns[attr] if assigns[attr]
        end
        ret
      end
    end
  end
end
