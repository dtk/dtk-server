module DTK; class Dependency
  class Simple < All
    def initialize(dependency_obj,node)
      super()
      @dependency_obj = dependency_obj
      @node = node
     end

    def depends_on_print_form?()
      if cmp_type = @dependency_obj.is_simple_filter_component_type?()
        Component.component_type_print_form(cmp_type)
      end
    end

    def self.augment_component_instances!(components,opts=Opts.new)
      return components if components.empty?
      sp_hash = {
        :cols => [:id,:group_id,:component_component_id,:search_pattern,:type,:description,:severity],
        :filter => [:oneof,:component_component_id,components.map{|cmp|cmp.id()}]
      }
      dep_mh = components.first.model_handle(:dependency)

      dep_objs = Model.get_objs(dep_mh,sp_hash)
      return components if dep_objs.empty?

      simple_deps = Array.new
      ndx_components = components.inject(Hash.new){|h,cmp|h.merge(cmp[:id] => cmp)}
      dep_objs.each do |dep_obj|
        cmp = ndx_components[dep_obj[:component_component_id]]
        dep = new(dep_obj,cmp[:node])
        simple_deps << dep
        (cmp[:dependencies] ||= Array.new) << dep
      end
      if opts[:ret_statisfied_by] and not simple_deps.empty?()
        satisify_cmps = get_components_that_satisify_deps(simple_deps)
        
        unless satisify_cmps.empty?
          simple_deps.each{|simple_dep|simple_dep.set_satisfied_by_component_ids?(satisify_cmps)}
        end
      end
      components
    end

    def self.dependency_exists?(cmp_template,antec_cmp_template)
      sp_hash = {
        :cols => [:id,:group_id,:component_component_id,:search_pattern,:type,:description,:severity],
        :filter => [:and,[:eq,:component_component_id,cmp_template.id()],
                    [:eq,:ref,antec_cmp_template.get_field?(:component_type)]]
      }
      !Model.get_objs(cmp_template.model_handle(:dependency),sp_hash).empty?
    end
    def self.create_component_dependency(cmp_template,antec_cmp_template)
      antec_cmp_template.update_object!(:display_name,:component_type)
      search_pattern = {
        ':filter' => [':eq', ':component_type',antec_cmp_template[:component_type]]
      }
      create_row = {
        :ref => antec_cmp_template[:component_type],
        :component_component_id => cmp_template.id(),
        :description => "#{antec_cmp_template.component_type_print_form()} is required for #{cmp_template.component_type_print_form()}",
        :search_pattern => search_pattern,
        :type => 'component',
        :severity => 'warning'
      }
      dep_mh = cmp_template.model_handle().create_childMH(:dependency)
      Model.create_from_row(dep_mh,create_row,:convert=>true)
    end

    def set_satisfied_by_component_ids?(satisify_cmps)
      match_cmp = satisify_cmps.find do |cmp|
        (cmp[:node_node_id] == @node[:id]) and @dependency_obj.component_satisfies_dependency?(cmp)
      end
      @satisfied_by_component_ids << match_cmp.id() if match_cmp
    end

    attr_reader :dependency_obj, :node
   private
    def self.get_components_that_satisify_deps(dep_list)
      ret = Array.new
      query_disjuncts = dep_list.map do |simple_dep|
        dep_obj = simple_dep.dependency_obj
        if filter = dep_obj.simple_filter_triplet?()
          [:and,[:eq,:node_node_id,simple_dep.node.id()],filter]
        else
          Log.error("Ignoring a simple dependency that is not a simple filter (#{simple_dep.dependency_obj})") 
          nil
        end
      end.compact
      if query_disjuncts.empty?
        return ret
      end
      cmp_mh = dep_list.first.node.model_handle(:component)
      filter = (query_disjuncts.size == 1 ? query_disjuncts.first : [:or] + query_disjuncts)
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_type,:node_node_id],
        :filter => filter
      }
      Model.get_objs(cmp_mh,sp_hash)
    end

  end
end; end
