module DTK; class NodeModuleDSL; class V1
  class ObjectModelForm < NodeModuleDSL::ObjectModelForm
    def convert(input_hash)
      NodeModule.new(input_hash.req(:module)).convert_children(input_hash)
    end

    class NodeModule < self
      def initialize(module_name)
        @module_name = module_name
      end
      def self.fields
        {
          module: {
            omit: true
          },
          module_type: {
            omit: true
          },
          dsl_version: {
            omit: true
          },
          node_images: {
            key: 'node_images',
            subclass: NodeImage
          },
          node_image_attributes: {
            key: 'node_image_attributes',
            subclass: NodeImageAttribute
          }
        }
      end

      class NodeImage < ObjectModelForm
        def self.prefixed_by_unique_key?
          true
        end
        def self.fields
          {
            properties: {},
            mappings: {}
          }
        end
      end
      class NodeImageAttribute < ObjectModelForm
        def self.fields
          {
            size: {}
          }
        end
      end
    end
  end
end; end; end

# example of a node module
# ---
# module: test_node_module
# dsl_version: 0.9.1
# module_type: node_module
# node_images:
#   centos6.4:
#     properties: #these are provide independent properties
#       description:
#       os_type: centos #required; rest are optional
#       dist_release: 6.4
#       architecture: x86_64
#       kernel_version: 3.2.0
#     mappings:
#      ec2: #keys are provider types
#       location: us-east-1
#       image: ami-96e20efe
#       location: us-west-1
#       image: ami-b21a20f7
#      docker:
#       location: https://registry.hub.docker.com #this could also point to cache on a docker host
#       image: centos/centos6.4
# node_image_attributes:
#  size:
#    small:
#      ec2: m1.small
#      docker: m1.small
#      vmware: m1.small
