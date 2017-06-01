require 'aws-sdk'

# TODO: replace with a 'dtk_module_require' method supplied by ruby provider
require_relative('../../dtk_stdlib/lib/dtk_stdlib')
module DTKModule
  module Aws
    module Stdlib
      require_relative('aws_stdlib/credential_handler')
      require_relative('aws_stdlib/resource')
      require_relative('aws_stdlib/mixin_aux')
    end
  end
end
