module XYZ
  class Nagios
    def initialize(service_check_assocs)
      @service_check_assocs = service_check_assocs
    end
    def generate_service_list(host_info)
      ret = ArrayObject.new
      return ret unless host_info[:services] and host_info[:host_address] and not host_info[:op_state] == "stopped"
      host_info[:services].each do |service, service_info|
        ret.concat(process_service(service,service_info))
      end
      ret
    end
   private
    def process_service(service,service_info)
      ret = ArrayObject.new
      return ret unless service_info[:to_monitor]
      service_info[:to_monitor].each do |m|
        if m[:name].to_sym == :inet_service_up
          r = process_service_simple_tcp_udp(service,service_info)
          ret << r if r
        else
          begin
            nagios_check_info = @service_check_assocs[m[:name]]
            next unless nagios_check_info
            check_command = nagios_check_info["command_name"]
            # find all keys of form ARG<n> and sort
            arg_keys = nagios_check_info.keys.map{|x|$1 if x=~/^ARG(.+)$/}.compact.sort.map{|y|"ARG"+y.to_str}
            unless arg_keys.empty?
              param_values = arg_keys.map{|x|Helper.ret_eval_value(nagios_check_info[x],service_info[:params])}
              check_command = "#{nagios_check_info["command_name"]}!#{param_values.join("!")}" 
            end
            ret << ret_hash(nagios_check_info[:service_description],check_command)
           rescue Exception
            Chef::Log.info("error while processing service check #{nagios_check_info["command_name"]||""}")
          end
        end
      end
      ret
    end

    def process_service_simple_tcp_udp(service,service_info)
      sap_params = (service_info[:params][:sap] if service_info[:params])
      port_info = Helper.ret_inet_port_info(sap_params)
      return nil unless port_info and port_info[:protocol] and port_info[:port]
      check_command = "check_#{port_info[:protocol]}!#{port_info[:port].to_s}"
      service_description = "#{service.gsub(/service\[/,"").gsub(/\]/,"")}_#{port_info[:protocol]}"
      ret_hash(service_description,check_command)
    end

     def ret_hash(service_description,check_command)
       HashObject.new({:service_description => service_description, :check_command => check_command},true)
     end

     class Helper
       class << self
         # helper fns that may be in arg to evaluae
         def ret_evalauted_args(attr_val_list,normalized_params)
           ret = Hash.new
           attr_val_list.each do |k,v|
             if k =~ /^ARG[0-9]+$/
               # TBD: looks like does not matter if eval of class_eval called
               ret[k] = ret_eval_value(v,normalized_params)
             end
           end
           ret
         end

         def ret_eval_value(val,normalized_params)
           eval("lambda{|params|#{val}}").call(normalized_params)
         end

         # helper fns
         def sap_inet_port(sap_params)
           port_info = ret_inet_port_info(sap_params)
           (port_info[:port] if port_info)
         end

         def ret_inet_port_info(sap_params)
           return nil unless sap_params
           sap_params.find{|s|s[:type] == "inet"}
         end
       end
     end
   end
end
