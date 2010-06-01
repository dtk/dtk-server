module XYZ
  class Project < Model
    set_relation_name(:project,:project)
    class << self
      def up()
        # no table specific columns (yet)
        one_to_many :component, :attribute_link, :node,:assoc_node_component, :node_group, :node_group_member, :network_partition, :network_gateway, :region,:assoc_region_network, :data_source
      end

      #### actions
      #TBD: stub
      def create(name,c,opts={})
        uri = "/project/#{name}"
        raise Error.new("Project #{name} exists already") if exists? IDHandle[:c => c,:uri => uri]
        project_id_handle = create_simple_instance?(uri,c,opts)
        hash = {:network_partition => {"internet" => {:is_internet => true}}} 
        create_from_hash(project_id_handle,hash)
      end

      def encapsulate_elements_in_project(project_id_handle,new_component_uri,opts={})
        raise Error.new("Project given (#{project_id_handle}) does not exist") unless exists? project_id_handle
        c = project_id_handle[:c]
        r = get_instance_or_factory(project_id_handle,nil,{:no_hrefs => true})
        raise Error.new("Error in Getting project info for #{project_id_handle}") if r.nil?
        els = r.values.first
        component_list = els[:component] ? 
        els[:component].values.map {|cmp|IDHandle[:c => c, :guid => cmp[:id]]} : []
        #if new_component_uri is created already remove it from component_list
        if new_id_info_row = get_row_from_id_handle(IDHandle[:c => c, :uri => new_component_uri])
           #TBD: implict assumptions that id uniquely identifies
           component_list.reject!{|x| x[:guid] == new_id_info_row[:id]}
        end

        link_list = els[:attribute_link] ? 
        els[:attribute_link].values.map {|link|IDHandle[:c => c, :guid => link[:id]]} : []
        encapsulate_into_component(c,new_component_uri,component_list,link_list)
      end

      def encapsulate_into_component(c,new_component_uri,component_list,link_list,opts={})
        new_component_id_handle = create_simple_instance?(new_component_uri,c)
        clone_helper = CloneHelper.new(@db)
        component_list.each do |cmp_id_handle|
          Object.clone(cmp_id_handle,new_component_id_handle,:component,clone_helper)
        end
        link_list.each do |link_id_handle|
          Object.clone(link_id_handle,new_component_id_handle,:attribute_link,clone_helper)
        end
  
        #must do setting of fks after all objects are cloned
        clone_helper.set_foreign_keys_to_right_values()

        component_list.each do |cmp_id_handle|
          Object.delete(cmp_id_handle)
        end
        link_list.each do |link_id_handle|
          Object.delete(link_id_handle)
        end
      end
    end    
  end
end
