
require 'rubygems'
require 'em-http-request'
EventMachine.run do
  http = EventMachine::HttpRequest.new('http://localhost:3000').get
  http.stream { |chunk| print chunk }
end
