
module XYZ
  #TBD: form not working yet: class Library < Model(:library,:library)
  class Library < Model
    set_relation_name(:library,:library)
    class << self 
      def up()
        #no table specfic fields (yet)
        one_to_many :component, :node,:assoc_node_component, :component_def, :node_group, :node_group_member, :attribute_link, :network_partition, :network_gateway, :region,:assoc_region_network_partition
      end

      ##### Actions
      #Idempotent
      #TBD: might refactor and put this code under chef processor or some with objects it is creating
      def import_chef_recipes(library_id_handle,cookbooks_uri=nil,opts={}) #TBD: cookbooks_uri is stub
  c = library_id_handle[:c]
        raise Error.new("Library given (#{library_id_handle}) does not exist") unless exists? library_id_handle
        cmp_fctr_id_handle = get_factory_id_handle(library_id_handle,:component)
        cmp_def_fctr_id_handle = get_factory_id_handle(library_id_handle,:component_def)
  ChefProcessor.get_cookbooks_metadata(cookbooks_uri) do |cookbook_name,cmp_obj,cmp_def_obj,error|
    if error
      if opts[:task]
        opts[:task].add_error(error)
        next
            else
              raise error 
            end
          end

    child_id_handle = get_child_id_handle(cmp_fctr_id_handle,cmp_obj.keys.first.to_sym)
    if exists? child_id_handle
      #TBD: may make task event; or may always conditionally happened to task or log
      Log.info("#{child_id_handle[:uri] || "recipe"} exists already\n")
    else
            cmp_def_uri = create_from_hash(cmp_def_fctr_id_handle,cmp_def_obj).first
      cmp_uri = create_from_hash(cmp_fctr_id_handle,cmp_obj).first
            Component.link_component_to_def(IDHandle[:c => c, :uri => cmp_uri], 
                                      IDHandle[:c => c, :uri => cmp_def_uri])

      opts[:task].add_event("added recipe #{cookbook_name}") if opts[:task]
    end
  end
        raise Error if (opts[:task] ? opts[:task].has_error? : nil)
      end
    end
  end
end
