require 'pp'
module DTKModule
  module DTK
    require_relative('dtk/response_or_error_hash_content')
    require_relative('dtk/response')
    require_relative('dtk/error')
    require_relative('dtk/attributes')
    require_relative('dtk/settings')
  end
  extend DTK::Attributes::Mixin
end
 
 
