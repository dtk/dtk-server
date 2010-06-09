
require File.expand_path("ec2", File.dirname(__FILE__))
=begin
Test code for new DSL
class TestDSL
  #auto vivification trick from http://t-a-w.blogspot.com/2006/07/autovivification-in-ruby.html
  @@rules ||= Hash.new {|h,k| h[k] = Hash.new(&h.default_proc)}
  def self.if_exists(condition,&block)
    context = self.new(Condition.new(:if_exists,condition))
    context.instance_eval(&block) 
  end

  def initialize(condition=nil)
    @condition = condition
  end
  def target()
    @@rules[@condition]
  end

  def self.source()
    Source.new()
  end
  def source()
    self.class.source()
  end

  class Condition
   def initialize(relation=:no_condition,condition=nil)
     @relation = relation
     @condition = condition 
   end
  end

  class Source < String
    def initialize()
      replace('source')
    end

    def [](a)
      replace("#{self}[#{a}]")
      self
    end
  end
end

class TestDSL
  if_exists(source[:private_ip_address]) do
    target[:eth0][:type] = 'ethernet' 
    target[:eth0][:family] = 'ipv4' 
    target[:eth0][:address] =  source[:private_ip_address] 
  end
  #debug statement to print the result of the pasring
  require 'pp'; pp @@rules
end

=end

module XYZ
  module DSAdapter
    class Ec2
      class NodeInstance < Ec2::Top 
       private
        #TBD below is effectively dsl; may make more declarative using data integration dsl
        def normalize(v)
          node_addr = v[:private_ip_address] ?
          {:family => "ipv4", :address => v[:private_ip_address]} : nil
          node_interface = {:node_interface => {"eth0" => {"type" => "ethernet"}.merge(node_addr ? {:address => node_addr} : {})}}
          addr_aps = addr_access_point(v[:ip_address],"ipv4","internet","internet")
          addr_aps.merge!(addr_access_point(v[:dns_name],"dns","internet","internet"))
          ret = node_interface.merge(addr_aps.empty? ? {} : {:address_access_point => addr_aps})
          #TBD: including local ip and dns plus and hookup to security groups 
        end

        def addr_access_point(addr,family,type,network_partition)
          if addr 
            attrs = {:type => type,:network_address => {:family => family, :address => addr}}
            attrs.merge!({Object.assoc_key(:network_partition_id) => "/network_partition/#{network_partition}"}) if network_partition
            {"#{type}_#{family}" => attrs}
          else
            {}
          end
        end

        def unique_keys(v)
          [:instance,v[:id]]
        end

        def relative_distinguished_name(v)
          v[:id]
        end
      end
    end
  end
end

