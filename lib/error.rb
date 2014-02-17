module DTK
  class Error ##TODO: cleanup; DTK::Error is coming from /home/dtk18/dtk-common/lib/errors/errors.rb  
    r8_nested_require('error','rest_error')
    r8_nested_require('error','usage')
    r8_nested_require('error','not_implemented')
    #TODO: may deprecate these two below
    r8_nested_require('error','not_found')
    r8_nested_require('error','amqp')
  end
end
