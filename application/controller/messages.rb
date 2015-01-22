module DTK
  class MessagesController < AuthController
    def rest__retrieve()
      messages = ::DTK::MessageQueue.retrive()
      rest_ok_response messages
    end
  end
end