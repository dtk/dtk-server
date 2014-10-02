module DTK; class Node
  class Template
    class Add < self
      def add()
        pp ret_node_templates_create_hash()
        nil
      end
      def initialize(target,node_template_name,image_id,opts={})
        @target = target
        @image_id = raise_error_if_invalid_image?(image_id,target)
        @node_template_name = node_template_name
        @os = raise_error_if_invalid_os(opts[:operating_system])
        @size_array = raise_error_if_invalid_size_array(opts[:size_array])
      end

     private
      def raise_error_if_invalid_image?(image_id,target)
        CommandAndControl.raise_error_if_invalid_image?(image_id,target)
        image_id
      end
      def raise_error_if_invalid_os(os)
          if os.nil?
            raise ErrorUsage.new("Operating system must be given")
          end
        os #TODO: stub
      end
      def raise_error_if_invalid_size_array(size_array)
        size_array ||= ['t1.micro'] #TODO: stub
        if size_array.nil?
          raise ErrorUsage.new("One or more image sizes must be given")
        end
        # size_array.each{|image_size|CommandAndControl.raise_error_if_invalid_image_size(image_size,target)}
        size_array
      end

      def ret_node_templates_create_hash()
        @size_array.inject(Hash.new) do |h,size|
          ref = node_template_ref(size)
          body = {
            :os_identifier => @node_template_name,
            :ami => @image_id,
            :display_name => node_template_display_name(size),
            :os_type => @os,
            :size => size
          }
          h.merge(ref => body)
        end
      end
      def node_template_ref(size)
        "#{@image_id}-#{size}"
      end
      def node_template_display_name(size)
        "#{@node_template_name} #{size}"
      end

    end
  end
end; end
=begin
  def create_public_library?(opts={})
    # TODO: hack; must unify; right now based on assumption on name that appears in import file
    if opts[:include_default_nodes]
      create_public_library_nodes?()
    else
      library_mh = pre_execute(:library)
      Library.create_public_library?(library_mh)
    end
  end

 def create_public_library_nodes?()
    container_idh = pre_execute(:top)
    hash_content = LibraryNodes.get_hash(:in_library => "public")
    hash_content["library"]["public"]["display_name"] ||= "public"
    Model.import_objects_from_hash(container_idh,hash_content)
 end

module XYZ
  class LibraryNodes
    def self.get_hash(opts={})
      ret = {"node"=> node_templates(opts), "node_binding_ruleset" => node_binding_rulesets()}
      if opts[:in_library]
        {"library"=> {opts[:in_library] => ret}}
      else
        ret
      end
    end
   private
    def self.node_templates(opts={})
       ret = Hash.new
       nodes_info.each do |k,info|
         ret[k] = node_info(info,opts)
      end
      ret["null-node-template"] = null_node_info(opts)
      ret
     end

     def self.node_binding_rulesets()
       ret_node_bindings_from_config_file()||Bindings
     end
     def self.nodes_info()
       ret_nodes_info_from_config_file()||NodesInfoDefault
     end

     def self.ret_nodes_info_from_config_file()
       unless content = ret_nodes_info_content_from_config_file()
         return nil
       end
       ret = Hash.new
       content.each do |ami,info|
         info["sizes"].each do |ec2_size|
           size = ec2_size.split(".").last
           ref = "#{ami}-#{size}"
           ret[ref] = {
             :os_identifier => info["type"],
             :ami => ami,
             :display_name =>"#{info["display_name"]} #{size}", 
             :os_type =>info["os_type"],
             :size => ec2_size,
             :png => info["png"]
           }
         end
       end
       ret
     end

=end
