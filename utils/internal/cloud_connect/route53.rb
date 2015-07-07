module DTK
  class CloudConnect
    class Route53 < self
      def initialize(dns_domain)
        @dns_domain = dns_domain
        dns = Fog::DNS::AWS.new(get_compute_params(just_credentials: true))
        unless @r8zone = dns.zones().find { |z| z.domain.include? dns_domain}
          raise ::DTK::Error.new("Bad dns_domain '#{dns_domain}'")
        end
      end
      
      def all_records
        request_context do
          @r8zone.records
        end
      end

      def get_record?(name, type=nil)
        request_context do
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
      end

      def destroy_record(name, type=nil)
        record = get_record?(name,type)
        request_context do
          record.nil? ? false : record.destroy
        end
      end

      ##
      # name           => dns name
      # value          => URL, DNS, IP, etc.. which it links to
      # type           => DNS Record type supports A, AAA, CNAME, NS, etc.
      #
      def create_record(name, value, type = 'CNAME', ttl=300)
        request_context do
          create_hash = { type: type, name: name, value: value, ttl: ttl }
          @r8zone.records.create(create_hash)
        end
      end

      ##
      # New value for records to be linked to
      #
      def update_record(record, value)
        request_context do
          # record is changed via Fog's modify
          record.modify(value: value)
        end
      end
    end
  end
end
