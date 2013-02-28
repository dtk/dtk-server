module DTK
  class Target
    class Instance < self

      def self.list(target_mh,opts={})
        sp_hash = {
          :cols => common_columns(),
          :filter => [:neq,:type,'template']
        }
        return get_objs(target_mh, sp_hash.merge(opts))
      end
    end
  end
end