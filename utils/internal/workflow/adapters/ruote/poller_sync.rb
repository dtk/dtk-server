#TODO: rewrite using EM periodic timer
module XYZ
  module WorkflowAdapter
    #generates polling requests that are listened to in reciever
    class RuotePoller
      include RuoteCommon
      def initialize(connection,receiver)
        common_init()
        @connection = connection
        @receiver = receiver
        @poll_items = Hash.new
        @original_ids = Hash.new
        @lock = Mutex.new()
        @cycle_time = 5
      end
      
      def add_item(poll_item)
        request_id = item.get_request_id()
        @lock.synchronize do
          @poll_items[request_id] = poll_item
          @original_ids[request_id] = request_id
        end
        request_id
      end
      
      def remove_item(request_id)
        @lock.synchronize do
          match_cur,match_orig = @original_ids.find{|cur,orig|orig == request_id} 
          if match_cur
            @original_ids.delete(match_cur)
            @poll_items.delete(match_cur)
          end
        end
      end

     private
      def poll
        while not is_stopped?()
          sleep @cycle_time
          #TODO: may splay for multiple items
          poll_items = nil
          @lock.synchronize{poll_items = @poll_items.dup}
          poll_items.each do |request_id,item|
            @reciever.subscribe(request_id)
            item.request(@connection)
            new_request_id = item.get_request_id()
            @lock.synchronize do
              @poll_items.delete(request_id)
              @poll_items[new_request_id] = item
              original_id = @original_ids.delete(request_id)
              @original_ids[new_request_id] = original_id
            end
          end
        end
      end
    end
  end
end
