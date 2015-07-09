module DTK; module CommandAndControlAdapter
  class Ec2
    class ClientToken
      def self.generate
        time_part = generate_time_part()
        if @last_time == time_part
          @num += 1
        else
          @num = 1
        end
        @last_time = time_part

        "#{tenant_part}-#{user_part}-#{time_part}-#{@num.to_s}"
      end

      private

      def self.generate_time_part
        Time.now.to_f.to_s.gsub(/\./,'-')
      end
      
      def self.tenant_part
        ::DtkCommon::Aux::running_process_user()
      end

      def self.user_part
        CurrentSession.get_username()
      end

    end
  end
end; end
