module DTK; class NodeModuleDSL; class V1
  class ObjectModelForm < NodeModuleDSL::ObjectModelForm
    def convert(input_hash)
      NodeModule.new(input_hash.req(:module)).convert_children(input_hash)
    end

=begin
      InputFormToInternal = Fields.inject(Hash.new){|h,(k,v)|h.merge(v[:key] => k)}
      Allkeys = Fields.values.map{|f|f[:key]}
      RequiredKeys =  Fields.values.select{|f|f[:required]}.map{|f|f[:key]}

      def convert(input_hash,context={})
        input_hash.inject(OutputHash.new) do |h,(k,v)|
          h.merge(key(k) => body(v,k,context))
        end
      end
=end
  private
    class NodeModule < self
      def initialize(module_name)
        @module_name = module_name
      end
      def self.fields()
        {
          :module => {},
          :module_type => {},
          :dsl_version => {},
          :node_images => {
            :key => 'node_images',
            :subclass => NodeImage
          },
          :node_image_attributes => {
            :key => 'node_image_attributes',
            :subclass => NodeImageAttribute
          }
        }
      end
     private
      def key(input_key)
         qualified_component(input_key)
      end
      def qualified_component(cmp)
        if @module_name == cmp
          cmp
        else
          "#{@module_name}#{ModCmpDelim}#{cmp}"
        end
      end

      def body(input_hash,cmp,context={})
        ret = OutputHash.new
        cmp_type = ret["display_name"] = ret["component_type"] = qualified_component(cmp)
        ret["basic_type"] = "service"
        ret.set_if_not_nil("description",input_hash["description"])
        external_ref = external_ref(input_hash.req(:external_ref),cmp)
        ret["external_ref"] = external_ref
        ret.set_if_not_nil("only_one_per_node",only_one_per_node(external_ref))
        add_attributes!(ret,cmp_type,input_hash)
        opts = Hash.new
        add_dependent_components!(ret,input_hash,cmp_type,opts)
        ret.set_if_not_nil("component_include_module",include_modules?(input_hash["include_modules"]))
        if opts[:constants]
          add_attributes!(ret,cmp_type,ret_input_hash_with_constants(opts[:constants]),:constant_attribute => true)
        end
        ret
      end
      class NodeImage
      end
      class NodeImageAttribute
      end
    end
  end
end; end; end
=begin
{ "dsl_version"=>"0.9.1",
 "module_type"=>"node_module",
 "node_images"=>
  {    {      {       "os_type"=>"centos",
       "dist_release"=>6.4,
       "architecture"=>"x86_64",
    "kernel_version"=>"3.2.0"},
     "mappings"=>
  {"ec2"=>{"location"=>"us-west-1", "image"=>"ami-b21a20f7"},
       "docker"=>
    {"location"=>"https://registry.hub.docker.com",
      "image"=>"centos/centos6.4"},
    "vmware"=>nil}},
"ubuntu12.04"=>nil},
 "components"=>{ "template_attributes"=>
{"size"=>
  {"small"=>
    {"ec2"=>"m1.small", "docker"=>"m1.small", "vmware"=>"m1.small"}}}}
=end
