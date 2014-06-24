#!/usr/bin/env ruby
require 'rubygems'
require 'chef'
require 'chef/application/solo'
require 'chef/client'
require 'git'
require 'json'
require 'popen4'

# TODO: move to be shared by agents
ChefSoloLogDir = "/var/log/chef"
CookbookPath =  "/var/chef/cookbooks"

module MCollective
  module Agent
    class Chef_solo < RPC::Agent
            metadata    :name        => "run chef actions",
                        :description => "Agent to initiate Chef solo runs",
                        :author      => "Reactor8",
                        :license     => "",
                        :version     => "",
                        :url         => "",
                        :timeout     => 300

      def initialize()
        super()
        @log = Log.instance
        @reply_data = nil
      end

      def run_action
        validate :run_list, :list
        validate :attributes, :list
        validate :task_id, :string 
        validate :top_task_id, :string
        log_params()
        @reply_data = nil
        @msg_id = request.uniqid
        @task_info = [:task_id,:top_task_id].inject({}) do |h,k|
          h.merge(k => request[k])
        end.merge(:msg_id => @msg_id)

        more_generic_response = Response.new()
        begin
          response = pull_recipes(request[:run_list])
          if response.failed?()
            set_reply!(response)
          else
            run_recipe(request[:run_list],request[:attributes])
          end
        rescue Exception => e
          more_generic_response.set_status_failed!()
          error_info = {
            :error => {
              :formatted_exception => e.inspect
            }
          }
          more_generic_response.merge!(error_info)
        end
        handler_response = RunHandler::ResponseHash.delete(request.uniqid)
        set_reply?(handler_response || more_generic_response)
      end
     private
      def pull_recipes(run_list)
        ret = Response.new
        cookbooks = run_list.map do |el|
          if el =~ /recipe\[(.+)\]/
            recipe = $1
            recipe.gsub(/::.+$/,"") + "/"
          end
        end.compact
        begin
          File.open("#{CookbookPath}/.git/info/sparse-checkout","w") do |f|
            f << (cookbooks.join("\n") + "\n")
          end
          g = Git.open(CookbookPath)
          g.pull('origin','origin/master')
          g.checkout
          ret.set_status_succeeded!()
         rescue Exception => e
          ret.set_status_failed!()
          error_info = {
            :error => {
              :formatted_exception => e.inspect
            }
          }
          ret.merge!(error_info)
        end
        ret 
      end

      def run_recipe(run_list,attributes)
        hash_attribs = (attributes||{}).merge({"run_list" => run_list||[]})
        @log.info("here1")
        File.open("/tmp/node.json", "w"){|f|f.puts(JSON.pretty_generate(hash_attribs))}
        @log.info("here2")
        cmd = "chef-solo -j /tmp/node.json"
        status =
          POpen4::popen4(cmd) do |stdout, stderr, stdin, pid|
          stdin.close
          @log.info("pid        : #{ pid }")
          @log.info("stdout     : #{ stdout.read.strip }")
          @log.info("stderr     : #{ stderr.read.strip }")
        end

        @log.info("here3; status=#{status.inspect}")

=begin
        chef_client = Chef::Application::Solo.new

        log_file_path = log_file_path()
        log_file = nil
        begin
          log_file = File.open(log_file_path,"a")
          Chef::Config[:log_location] = log_file
          most_recent_link = most_recent_file_path()
          File.delete(most_recent_link) if File.exists? most_recent_link
          File.symlink(log_file_path,most_recent_link)
          # so does not look file json attributes file
          Chef::Config[:json_attribs] = nil

          chef_client.reconfigure
          handler = RunHandler.new(@msg_id,@task_info)
          Chef::Config[:report_handlers] << handler
          Chef::Config[:exception_handlers] << handler
          chef_client.setup_application
          hash_attribs = (attributes||{}).merge({"run_list" => run_list||[]})
          Chef::Client.new(hash_attribs).run
         ensure
          log_file.close
        end
=end
      end
      def set_reply!(response)
        reply.data = @reply_data = response.to_hash
      end
      def set_reply?(response)
        reply.data = @reply_data ||= response.to_hash
      end
      def log_params()
        @log.info("params: #{request.data.inspect}")
      end
      
      def log_file_path()
        "#{ChefSoloLogDir}/#{id_info()}.log"
      end
      def most_recent_file_path()
        "#{ChefSoloLogDir}/last.log"
      end
      def id_info()
        [:msg_id,:task_id,:top_task_id].map do |k|
          if @task_info.has_key?(k)
            "#{k}:#{@task_info[k].to_s}"
          end
        end.compact.join(":")
      end

      # TODO: this should be common accross Agents
      class Response < Hash
        def initialize(hash={})
          super()
          self.merge!(hash)
          self[:status] = :unknown unless hash.has_key?(:status)
        end
        
        def to_hash()
          Hash.new.merge(self)
        end

        def failed?()
          self[:status] == :failed
        end

        def set_status_failed!()
          self[:status] = :failed
        end
        def set_status_succeeded!()
          self[:status] = :succeeded
        end
      end
      class ResponseFailed < Response
        def initialize(error,info={})
          super({:status => :failed, :error => error}.merge(info))
        end
      end
      class ResponseSucceeded < Response
        def initialize(info={})
          super({:status => :succeeded}.merge(info))
        end
      end

      class RunHandler < Chef::Handler
        ResponseHash = {}
        def initialize(msg_id,task_info)
          super()
          @msg_id = msg_id
          @task_info = task_info
        end
        def report()
          response = Response.new(:node_name => node.name)
          if success?()
            response.set_status_succeeded!()
          else
            response.set_status_failed!()
            error_info = {
              :error => {
                # TODO: log the backtrace, rather than returning it
                #          :backtrace =>  Array(backtrace),
                :formatted_exception => run_status.formatted_exception
              }
            }
            response.merge!(error_info)
            Chef::Log.info("error: #{run_status.formatted_exception}")
            Chef::Log.info("backtrace: \n #{Array(backtrace).map{|l|"   #{l}"}.join("\n")}")
          end
          RunHandler::ResponseHash[@msg_id] = response
        end
      end
    end
  end
end


