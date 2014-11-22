module DTK; class Component
  module Dependency
    module ClassMixin
      def get_nested_dependencies(component_idhs)
        ret = Array.new
        return ret if component_idhs.empty?
        cmp_cols = [:id,:group_id,:only_one_per_node,:component_type,:extended_base,:implementation_id]
        sp_hash = {
          :cols => [:dependencies] + cmp_cols,
          :filter => [:oneof,:id,component_idhs.map{|idh|idh.get_id()}]
        }
        cmp_mh = component_idhs.first.createMH()
        Component.get_objs(cmp_mh,sp_hash)
      end
      
      # returns hash with ndx component_id and keys :constraints, :component
      # opts can have key :when_evaluated
      def get_ndx_constraints(component_idhs,opts={})
        ret = Hash.new
        return ret if component_idhs.empty?
        get_nested_dependencies(component_idhs).each do |r|
          pntr = ret[r[:id]] ||= {:constraints => Array.new, :component => r.slice(*cmp_cols)}
          pntr[:constraints] << Constraint.create(r[:dependencies]) if r[:dependencies]
        end
        ret.each_value do |r|
          cmp = r[:component]
          unless opts[:when_evaluated] == :after_cmp_added
            # these shoudl only be evaluated before component is evaluated
            r[:constraints] << Constraint::Macro.only_one_per_node(cmp[:component_type]) if cmp[:only_one_per_node]
            r[:constraints] << Constraint::Macro.base_for_extension(cmp) if cmp[:extended_base]
          end
        end
        ret
      end
    end
    module Mixin
      # TODO: may deprecate this to be in terms of get_ndx_constraints
      def get_constraints!(opts={})
        # TODO: may see if precalculating more is more efficient
        cmp_cols = [:only_one_per_node,:component_type,:extended_base,:implementation_id]
        rows = get_objs(:cols => [:dependencies] + cmp_cols)
        cmp_info = rows.first #just picking first since component info same for all rows
        cmp_cols.each{|col|self[col] = cmp_info[col]} if opts[:update_object]
        
        constraints = rows.map{|r|Constraint.create(r[:dependencies]) if r[:dependencies]}.compact
        constraints << Constraint::Macro.only_one_per_node(cmp_info[:component_type]) if cmp_info[:only_one_per_node]
        constraints << Constraint::Macro.base_for_extension(cmp_info) if cmp_info[:extended_base]
        
        return Constraints.new() if constraints.empty?
        Constraints.new(:and,constraints)
      end
    end
  end
end; end
    
