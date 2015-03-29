module DTK; class ModuleRef
  class Lock
    class Info
      attr_reader :namespace,:module_name,:level,:children_module_names
      attr_accessor :implementation,:module_branch
      def initialize(namespace,module_name,level,extra_fields={})
        @namespace             = namespace
        @module_name           = module_name
        @level                 = level
        @children_module_names = extra_fields[:subtree_module_names] || []
        @implementation        = extra_fields[:implementation]
        @module_branch         = extra_fields[:module_branch]
      end

      def self.create_from_hash(mh,info_hash)
        impl = info_hash[:implementation]
        mb = info_hash[:module_branch]
        extra_fields = {
          :children_module_names => info_hash[:children_module_names],
          :implementation        => object_form(mh.createMH(:implementation),info_hash[:implementation]),
          :module_branch         => object_form(mh.createMH(:module_branch),info_hash[:module_branch])
        }
        new(info_hash[:namespace],info_hash[:module_name],info_hash[:level],extra_fields)
      end

      def hash_form()
        ret = {
          :namespace             => @namespace,
          :module_name           => @module_name,
          :level                 => @level,
          :children_module_names => @children_module_names
        }
        ret.merge!(:implementation => @implementation) if implementation
        ret.merge!(:module_branch => module_branch) if module_branch
        ret
      end

      def children_and_this_module_names()
        [@module_name] + @children_module_names
      end
     private

      def self.object_form(mh,hash)
        ret = nil
        return ret unless hash
        unless id = hash[:id]
          Log.error_pp(["Unexpected that hash does not have :id field",hash])
          return ret
        end
        mh.createIDH(:id => id).create_object(hash)
      end
    end
  end
end; end

