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
        ret = PrettyPrintHash.new
        ret[:version] = @parent.version()
        @old_version_hash.inject(ret) do |h,(cmp,cmp_info)|
          #TODO: stub
          h.merge(cmp=>cmp_info)
        end
      end
      private
    end
  end
end
