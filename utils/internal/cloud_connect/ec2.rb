module DTK
  class CloudConnect
    class Route53 < self
      def initialize(dns_domain)
        @dns_domain = dns_domain
        dns = Fog::DNS::AWS.new(get_compute_params(:just_credentials=>true))
        @r8zone = GatedConnection.new(dns.zones().find { |z| z.domain.include? dns_domain})
      end
      
      def all_records()
        @r8zone.records
      end

      def get_record(name, type=nil)
        5.times do
          begin
            return @r8zone.records.get(name,type)
          rescue Excon::Errors::SocketError => e
            Log.warn "Handled Excon Socket Error: #{e.message}"
          end
        end
        
          # if this happens it means that we need to look into more Excon::Errors::SocketError,
        # at the moment this is erratic issue which happens from time to time
        raise "Not able to get DNS record after 5 re-tries, aborting process."
      end

      def destroy_record(name, type=nil)
        record = get_record(name,type)
        record.nil? ? false : record.destroy
      end
      
      ##
      # name           => dns name
      # value          => URL, DNS, IP, etc.. which it links to
      # type           => DNS Record type supports A, AAA, CNAME, NS, etc.
      #
      def create_record(name, value, type = 'CNAME', ttl=300)
        request_context do
          create_hash = { :type => type, :name => name, :value => value, :ttl => ttl }
          @r8zone.records.create(create_hash)
        end
      end
      
      ##
      # New value for records to be linked to
      #
      def update_record(record, value)
        # record is changed via Fog's modify
          record.modify(:value => value)
      end
    end 
  end
end
