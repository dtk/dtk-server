require 'aws-sdk'

# TODO: replace with a 'dtk_module_require' method supplied by ruby provider
require_relative('../../dtk_stdlib/lib/dtk_stdlib')
module DTKModule
  module Aws
    module Stdlib
      require_relative('aws_stdlib/aws_credential_handle')
      require_relative('aws_stdlib/resource')
      require_relative('aws_stdlib/attributes')
      require_relative('aws_stdlib/mixin_aux')
      
      def self.wrap(av_hash, &body)
        DTKModule.wrap(av_hash, attributes_class: Aws::Stdlib::Attributes, &body)
      end
    end
  end
end
