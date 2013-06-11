module DTK; class Dependency
  class Simple < All
    def initialize(dependency_obj,node)
      @dependency_obj = dependency_obj
      @node = node
     end

    def scalar_print_form?()
      if cmp_type = @dependency_obj.is_simple_component_type_match?()
        Component.component_type_print_form(cmp_type)
      end
    end

    def self.augment_component_instances!(cmp_instances,opts=Opts.new)
      return cmp_instances if cmp_instances.empty?
      sp_hash = {
        :cols => [:id,:group_id,:component_component_id,:search_pattern,:type,:description,:severity],
        :filter => [:oneof,:component_component_id,cmp_instances.map{|cmp|cmp.id()}]
      }
      dep_mh = cmp_instances.first.model_handle(:dependency)

      dep_objs = Model.get_objs(dep_mh,sp_hash)
      return cmp_instances if dep_objs.empty?

      simple_deps = Array.new
      ndx_cmp_instances = cmp_instances.inject(Hash.new){|h,cmp|h.merge(cmp[:id] => cmp)}
      dep_objs.each do |dep_obj|
        cmp = ndx_cmp_instances[dep_obj[:component_component_id]]
        dep = new(dep_obj,cmp[:node])
        simple_deps << dep
        (cmp[:dependencies] ||= Array.new) << dep
      end
      if opts[:ret_statisfied_by] and not simple_deps.empty?()
        satisify_cmps = get_components_that_satisify_deps(simple_deps)
        
        unless satisify_cmps.empty?
          pp [satisify_cmps,satisify_cmps]
          simple_deps.each{|simple_dep|simple_dep.set_satisfied_by_component_id(satisify_cmps)}
        end
      end
      pp [:test,cmp_instances.map{|r|r[:dependencies]}]
      cmp_instances
    end

    def self.add_component_dependency(component_idh, type, hash_info)
      #TODO: bug problem may be need to get parent of component to use craete rows
      #TODO: stubbed
#      cmp = component_idh.create_object.update_object!(:display_name,:library_library_id,:group_id)
      cmp = component_idh.create_object.update_object!(:display_name)
      other_cmp_idh = component_idh.createIDH(:id => hash_info[:other_component_id])
      other_cmp = other_cmp_idh.create_object.update_object!(:display_name,:component_type)
      search_pattern = {
        ":filter" => [":eq", ":component_type",other_cmp[:component_type]]
      }
      create_row = {
        :ref => other_cmp[:component_type],
        :component_component_id => component_idh.get_id(),
        :description => "#{other_cmp[:display_name]} #{type} #{cmp[:display_name]}",
        :search_pattern => search_pattern,
        :severity => "warning",
        :library_library_id => cmp[:library_library_id]
      }
      dep_mh = component_idh.createMH(:dependency)
      Model.create_from_row(dep_mh,create_row)
    end

    def set_satisfied_by_component_id(satisify_cmps)
      @satisfied_by_component_id = 0 #TODO: stub
    end

    attr_reader :dependency_obj, :node
    private
    def self.get_components_that_satisify_deps(dep_list)
      ret = Array.new
      query_disjuncts = dep_list.map do |simple_dep|
        dep_obj = simple_dep.dependency_obj
        if simple_filter = dep_obj.simple_filter?()
          [:and,[:eq,:node_node_id,simple_dep.node.id()],simple_filter]
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
