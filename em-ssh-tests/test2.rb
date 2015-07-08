#!/usr/bin/env ruby
require 'eventmachine'
require "em-ssh"
require 'net/scp'
require 'tempfile'
require 'pp'

# NOTE: this is content generated from install_script, we will use CommandAndControl.install_script(node) to generate this
# and this content will be different for every node (because of pbuilderid)
InstallScriptContent = "#!/bin/sh \ncat << EOF >> /etc/mcollective/server.cfg\n---\nplugin.stomp.host = ec2-54-226-228-161.compute-1.amazonaws.com\nmain_collective = mcollective\ncollectives = mcollective\n\nplugin.stomp.user = mcollective\nplugin.stomp.password = marionette\nEOF\n\ncat << EOF > /etc/mcollective/facts.yaml\n---\ngit-server: \"git22@ec2-54-226-228-161.compute-1.amazonaws.com\"\npbuilderid: physical--imported_node_1\nEOF\n\nmkdir -p /etc/mcollective/ssh\n\ncat << EOF > /etc/mcollective/ssh/mcollective\n-----BEGIN RSA PRIVATE KEY-----\nMIIEpQIBAAKCAQEAogsCWIM7H/meCD4YxYqTPevCQIpN+oqcQJcXG1YBIjaeltfk\nUrnOfG92lTrMfZWT8BEgz0c1KP7qkn0dGXT1aBd4ntkD9hxNz9z6z6Q6bENgTaJ7\nDllyHwn4EgATbz8/WCto1y0AgujuBYXZlGhrUeO/IexuFvCGloegq4ECRTH8mpdm\ntgoCCc2h3e/uooVicnUQXSFBKkexLq3UTt7BmfpkGQ18ikZ62PUV0pkaQyXIu43X\n2xlGrkNyEIV1YRIcHkQ2jZgX/eLkOTpzm0P9IWipT2G3K5hAPGF7eVdjs+EF3IWb\ngrJINZbx+litg3cBSavAOzMZ5e95idIbq8ObOQIDAQABAoIBAFcExnu17XhcWite\n/XqH0k58XtK98uZKrWJaQQRjCTTQVBX5Vhm+wk48pVe6PbprKwjOieoF+VxMmLeW\nDJxxHKCLijDzpZby2C56Iw6CyQT+oabPTHoGOqzEc71m4Qjq1B+LID/9YLrsT3YT\nzSZPdOKDBU84Yl5bSEtqBjRTkV6KgF8+DSCYWJF0+zXFGBA8ZGqDXf9SWX4wccBX\n3v4gNuSTIN/XO49grxESvvNNlcS8CRClAOJ3CEtaBRBdnb53oybDwAuOJXYl/t24\n0U4EWXArrdOAHjHvncWPFbmkV6i/WQYW/PThtE2qoFR8cxg9nxczuREqnb+vJ/OE\n37oAwqECgYEA11Ji54eto4ipr9wVETpKJimLwX+83kNqfXkeUyM4+1fQR14vpUHq\n25Gb5rUzZeQbTlva7Ns6XSrwl4s/hNLOp4ZUkddyCKUuUi3IJXtXDj7d6wPbiROn\nt9K4MYoJ+LlZaYgrxtYB0vhdSiNvpRkQZGGhlKCu2viT6KYVEdGIWnUCgYEAwKfl\n9uB14LW8BkvQfk/rITvOJLMr58OhIk3dmkt4O2SGzRZmwYO2McN8vTCJ2TCThWG0\nvWj+pnVxUF7gUlE112K2lJysgSrarb78H/VCSjLS6mkK1JCsnFW5cTV7LRzmMD4Q\nOaNfsZpl4aFeQ1+WJVhyGUu6LtIHsyUj0zuvPTUCgYEAkUWMZRktFYBGu9eIfy8M\nh+LP36UHEA378tuckgrZjvoYE46AJsbqZWk//c+S9dOIeL2QXu0p22H1IMlZ+Ysg\n0fXXaO4qiZqoPdmVh3RHr9zKbJ0VqM4SAfuxOfsf7ydeI80ze9s3L9dRWYu+72yR\nmqgkE9q1HhdH81baMENl82ECgYEAvr69kiQEsdpdckJoCFeqLnpfDLkU9GAdzrAX\ng2fLf8p1KONQE7MLldO+UjaXlSFiPgJSB+LHlhnbej6ljPr4+uqyaQuCRFUgtDvO\ntvmGi54sc4hS/8jKDfNWKr9P2IevZP5d5CNcYKTE0JOLl9sw9oLOXTs7+JVcqENS\naBbE1y0CgYEAxOoBvmJHwVb9bxrT1nIulH1SsTYrrrZDXlXhfSOqXXuY5Oioqx53\noj/9w0inL0iN6TDPrwexhaWtGFVnaH4M/7atdVbgeG4lDmTA3JV9f8T4OBDCK9zI\nELKfOMJlu9g6VggKZilpcG+X+Qb8B4+g5SddcGtgVz4UMKjKNwCj1fA=\n-----END RSA PRIVATE KEY-----\n\nEOF\n\ncat << EOF > /etc/mcollective/ssh/mcollective.pub\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiCwJYgzsf+Z4IPhjFipM968JAik36ipxAlxcbVgEiNp6W1+RSuc58b3aVOsx9lZPwESDPRzUo/uqSfR0ZdPVoF3ie2QP2HE3P3PrPpDpsQ2BNonsOWXIfCfgSABNvPz9YK2jXLQCC6O4FhdmUaGtR478h7G4W8IaWh6CrgQJFMfyal2a2CgIJzaHd7+6ihWJydRBdIUEqR7EurdRO3sGZ+mQZDXyKRnrY9RXSmRpDJci7jdfbGUauQ3IQhXVhEhweRDaNmBf94uQ5OnObQ/0haKlPYbcrmEA8YXt5V2Oz4QXchZuCskg1lvH6WK2DdwFJq8A7Mxnl73mJ0hurw5s5 dtk22@dtk22-25\n\nEOF\n\ncat << EOF > /etc/mcollective/ssh/authorized_keys\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOWu0cXOSM8wE/1O2fMCKR7ve4BkYExqpM2SvJgLiW7SMkcNfnPLl4foa3uQPVqHX3YkhrrUIda4P53QWK7CQcqLqUeybURrH1ZyLOhABCfxQebazrac3E0GbEEkuVUplAd0ThkrdFFTy8vL5BnjcLY7cdjSDEFhrCojzPCI6QmnSWmDjJ7D9hY9GOwZzqBFxiiD0cgUZrtUvRghd/w/UUqxbPOAPWrujN/Jmc+16Zw8WMTW45LrtUc2XnK6epPFhvP2rEGPIEsg6a2l4ViWvRqZlOp0x3EqvsHGSFZaiK5/EmR3qj2A2jzg89heaCvBHO+9Z4YUr7D3Hu/32/p/j3 dtk22@dtk22-25\n\nEOF\n\nssh-keygen -f \"/root/.ssh/known_hosts\" -R ec2-54-226-228-161.compute-1.amazonaws.com\ncat << EOF >>/root/.ssh/known_hosts\n|1|opT8ph2zsOk1aNNxsrVPZr2I/Jo=|V443cfBsN3Uh/pUUixyOu4T/C1Q= ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcNFXOld8aRO+hYOL/F5AnoN0A4b16OVWRk6PMZVUAiPeZ2cFsIbkCgELByazyyEVjs5PlfLfgU1IqjEeFF7kDaj/f9GXCjuxGWAEBkbqzJ3nW7iPBPCm+0jPbNLD+s2boAKeGp1jDS5h5SANhbaale1kSLo3+MqGn5A69Pt+nO4KTZkYh2h7jHM5D7fY297x07MJbPyzC/KergY22TkP7P1BfLzDDrVLrvz++6YSbMAOrY7OSY/vl1hdI4Z4yQMlFHvLZ+SYbA76Y0jndW7ooLaBlQEYarEu1BtYPZ2F+CrivUb4MzmEZ0I2vxMegDwHJ13pQy6sfX0aungfUyk1H\n\nEOF\n\n\n/etc/init.d/mcollective* restart\n\n\n"

EM.run do
  host =  ARGV[0]
  user = ARGV[1]
  password = ARGV[2]
  EM::Ssh.start(host, user, password: password) do |connection|
    connection.errback do |err|
      $stderr.puts "#{err} (#{err.class})"
      EM.stop
    end
    connection.callback do |ssh|
      install_script_file_path = nil

      # ********************************************
      # NOTE for Rich :
      #
      # if using ssh.exec (without '!') e.g. ssh.exec('ping -c 1 www.google.com')
      # then commands will execute in parallel
      #
      # if using ssh.exec! (with '!') e.g. ssh.exec!("rm -rf /tmp/dtk-node-agent")
      # commands will execute in sequential order and I think this is what we need here,
      # because we need e.g 'rm -rf /tmp/dtk-node-agent' to finish before we can upload new one, etc.
      # ********************************************

      # making sure dtk-node-agent directory is deleted from node before uploading
      ssh.exec!("rm -rf /tmp/dtk-node-agent") do |_channel, _stream, data|
        puts data #if stream == :stdout
      end

      # executing SCP commands to upload dtk-node-agent directory and install_script to node
      begin
        # using Tempfile library to generate install_script content
        install_script_file = Tempfile.new("install_script")
        install_script_file.write(InstallScriptContent)
        install_script_file.close
        install_script_file_path = install_script_file.path

        # getting home path on unix system, we will use R8.app_user_home() in code
        home_path = Etc.getpwuid(Process.uid).dir

        # executing upload commands
        Net::SCP.upload!(host, user, install_script_file.path, "/tmp", ssh: { password: password, port: "22" }, recursive: true)
        Net::SCP.upload!(host, user, "#{home_path}/dtk-node-agent", "/tmp", ssh: { password: password, port: "22" }, recursive: true)
      rescue Exception => e
        # if error when uploading dtk-node-agent or install_script then print error
        # close ssh connection and exit EM.run (do not continue with execution)
        puts "Error occured in SCP.upload: #{e}"
        ssh.close
        exit
      ensure
        install_script_file.unlink
      end

      # execute dtk-node-agent/install_agent.sh script and stream stdout back to console
      # if some errors returned then store them to errors and print them after script is executed
      errors = ""
      install_command = user.eql?('root') ? "bash /tmp/dtk-node-agent/install_agent.sh" : "sudo bash /tmp/dtk-node-agent/install_agent.sh"

      puts "\nEXECUTING: #{install_command}"
      ssh.exec!(install_command) do |_channel, stream, data|
        if stream == :stderr
          errors << data
        else
          puts data
        end
      end

      # print all errors that happened while executing install_agent.sh
      puts "\nWarnings or errors occured while executing '#{install_command}':\n#{errors}" unless errors.empty?

      # delete dtk-node-agent folder from node
      puts "\nEXECUTING: 'rm -rf /tmp/dtk-node-agent'"
      ssh.exec!("rm -rf /tmp/dtk-node-agent") do |_channel, _stream, data|
        puts data #if stream == :stdout
      end

      # execute install_script generated on server side and uploaded to node and stream stdout back to console
      # if some errors returned then store them to errors and print them after script is executed
      errors = ""
      install_script_command = user.eql?('root') ? "bash #{install_script_file_path}" : "sudo bash #{install_script_file_path}"

      puts "\nEXECUTING: '#{install_script_command}'"
      ssh.exec!(install_script_command) do |_channel, stream, data|
        if stream == :stderr
          errors << data
        else
          puts data
        end
      end

      # print all errors that happened while executing install_script
      puts "\nWarnings or errors occured while executing '#{install_script_command}':\n#{errors}" unless errors.empty?

      # delete install_script from node
      puts "\nEXECUTING: rm -rf #{install_script_file_path}"
      ssh.exec!("rm -rf #{install_script_file_path}") do |_channel, _stream, data|
        puts data #if stream == :stdout
      end

      puts "\nCOMPLETED SUCCESSFULLY!"
    end
  end
end
