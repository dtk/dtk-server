# TODO: thing we wil be able to deprecate this
module DTK; class ModuleRefs
  class Lock
    class MissingInformation < self
      def initialize(assembly_instance, missing, complete, types, opts)
        super(assembly_instance)
        @missing = missing
        @complete = complete
        @types = types
        @opts = opts
      end

      # types will be subset of [:locked_dependencies, :locked_branch_shas]
      # opts can have
      #  :with_module_branches - Boolean
      def self.missing_information?(module_refs_lock, types, opts = {})
        # partition into rows that are missing info and ones that are not
        missing = {}
        complete = {}
        module_refs_lock.each_pair do |module_name, module_ref_lock|
          if el_missing_information?(module_ref_lock, types, opts)
            missing[module_name] = module_ref_lock
          else
            complete[module_name] = module_ref_lock
          end
        end
        unless missing.empty?
          new(module_refs_lock.assembly_instance, missing, complete, types, opts)
        end
      end

      private

      def self.el_missing_information?(module_ref_lock, types, opts = {})
        if types.include?(:locked_dependencies)
          unless info = module_ref_lock.info
            return true
          end
          if opts[:with_module_branches]
            unless info.module_branch
              return true
            end
          end
        end
        if types.include?(:locked_branch_shas)
          unless module_ref_lock.locked_branch_sha
            return true
          end
        end
        false
      end
    end
  end
end; end
