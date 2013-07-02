
module DTK
  class TestController < AuthController
    helper :module_helper

    Frequency = 0.5


    def rest__test_em_defer()
      rest_async_response do |body|
        body.send "#{Time.now}"
        sleep(2)
        body.send "#{Time.now}"
        sleep(2)
        body.send "#{Time.now}"
        sleep(2)
        body.send "#{Time.now}"
      end
    end

    def repeat(body,index)
      #emulate pieces of work being completed
      EM.add_timer(Frequency) do
        
        puts "part #{(index).to_s}\n + #{Time.now}"
        body.send "part #{(index).to_s}\n + #{Time.now}"
     
        EM.next_tick do
          if index == 0
            body.succeed
          else

            repeat(body,index-1)
          end
        end
      end
    end

  end
end
