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

      class NodeImage < ObjectModelForm
        def self.prefixed_by_unique_key?()
          true
        end
        def self.fields()
          {
            :properties => {},
            :mappings => {}
          }
        end
      end
      class NodeImageAttribute < ObjectModelForm
        def self.fields()
          {
            :size => {}
          }
        end
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
