module DTK
  class Target
    class Instance < self
      def self.list(target_mh,opts={})
        filter = [:neq,:type,'template']
        if opts[:filter]
          filter = [:and,filter,opts[:filter]]
        end
        sp_hash = {
          :cols => [:id, :display_name, :iaas_type, :type, :parent_id, :provider, :is_default_target],
          :filter => filter
        }
        get_objs(target_mh, sp_hash)
      end
    end
  end
end
