#!/usr/bin/env ruby
require 'eventmachine'
require 'em-ssh'
require 'net/scp'
require 'tempfile'
require 'pp'

# NOTE: this is content generated from install_script, we will use CommandAndControl.install_script(node) to generate this
# and this content will be different for every node (because of pbuilderid)
InstallScriptContent = "#!/bin/sh \ncat << EOF >> /etc/mcollective/server.cfg\n---\nplugin.stomp.host = ec2-54-226-228-161.compute-1.amazonaws.com\nmain_collective = mcollective\ncollectives = mcollective\n\nplugin.stomp.user = mcollective\nplugin.stomp.password = marionette\nEOF\n\ncat << EOF > /etc/mcollective/facts.yaml\n---\ngit-server: \"git22@ec2-54-226-228-161.compute-1.amazonaws.com\"\npbuilderid: physical--imported_node_1\nEOF\n\nmkdir -p /etc/mcollective/ssh\n\ncat << EOF > /etc/mcollective/ssh/mcollective\n-----BEGIN RSA PRIVATE KEY-----\nMIIEpQIBAAKCAQEAogsCWIM7H/meCD4YxYqTPevCQIpN+oqcQJcXG1YBIjaeltfk\nUrnOfG92lTrMfZWT8BEgz0c1KP7qkn0dGXT1aBd4ntkD9hxNz9z6z6Q6bENgTaJ7\nDllyHwn4EgATbz8/WCto1y0AgujuBYXZlGhrUeO/IexuFvCGloegq4ECRTH8mpdm\ntgoCCc2h3e/uooVicnUQXSFBKkexLq3UTt7BmfpkGQ18ikZ62PUV0pkaQyXIu43X\n2xlGrkNyEIV1YRIcHkQ2jZgX/eLkOTpzm0P9IWipT2G3K5hAPGF7eVdjs+EF3IWb\ngrJINZbx+litg3cBSavAOzMZ5e95idIbq8ObOQIDAQABAoIBAFcExnu17XhcWite\n/XqH0k58XtK98uZKrWJaQQRjCTTQVBX5Vhm+wk48pVe6PbprKwjOieoF+VxMmLeW\nDJxxHKCLijDzpZby2C56Iw6CyQT+oabPTHoGOqzEc71m4Qjq1B+LID/9YLrsT3YT\nzSZPdOKDBU84Yl5bSEtqBjRTkV6KgF8+DSCYWJF0+zXFGBA8ZGqDXf9SWX4wccBX\n3v4gNuSTIN/XO49grxESvvNNlcS8CRClAOJ3CEtaBRBdnb53oybDwAuOJXYl/t24\n0U4EWXArrdOAHjHvncWPFbmkV6i/WQYW/PThtE2qoFR8cxg9nxczuREqnb+vJ/OE\n37oAwqECgYEA11Ji54eto4ipr9wVETpKJimLwX+83kNqfXkeUyM4+1fQR14vpUHq\n25Gb5rUzZeQbTlva7Ns6XSrwl4s/hNLOp4ZUkddyCKUuUi3IJXtXDj7d6wPbiROn\nt9K4MYoJ+LlZaYgrxtYB0vhdSiNvpRkQZGGhlKCu2viT6KYVEdGIWnUCgYEAwKfl\n9uB14LW8BkvQfk/rITvOJLMr58OhIk3dmkt4O2SGzRZmwYO2McN8vTCJ2TCThWG0\nvWj+pnVxUF7gUlE112K2lJysgSrarb78H/VCSjLS6mkK1JCsnFW5cTV7LRzmMD4Q\nOaNfsZpl4aFeQ1+WJVhyGUu6LtIHsyUj0zuvPTUCgYEAkUWMZRktFYBGu9eIfy8M\nh+LP36UHEA378tuckgrZjvoYE46AJsbqZWk//c+S9dOIeL2QXu0p22H1IMlZ+Ysg\n0fXXaO4qiZqoPdmVh3RHr9zKbJ0VqM4SAfuxOfsf7ydeI80ze9s3L9dRWYu+72yR\nmqgkE9q1HhdH81baMENl82ECgYEAvr69kiQEsdpdckJoCFeqLnpfDLkU9GAdzrAX\ng2fLf8p1KONQE7MLldO+UjaXlSFiPgJSB+LHlhnbej6ljPr4+uqyaQuCRFUgtDvO\ntvmGi54sc4hS/8jKDfNWKr9P2IevZP5d5CNcYKTE0JOLl9sw9oLOXTs7+JVcqENS\naBbE1y0CgYEAxOoBvmJHwVb9bxrT1nIulH1SsTYrrrZDXlXhfSOqXXuY5Oioqx53\noj/9w0inL0iN6TDPrwexhaWtGFVnaH4M/7atdVbgeG4lDmTA3JV9f8T4OBDCK9zI\nELKfOMJlu9g6VggKZilpcG+X+Qb8B4+g5SddcGtgVz4UMKjKNwCj1fA=\n-----END RSA PRIVATE KEY-----\n\nEOF\n\ncat << EOF > /etc/mcollective/ssh/mcollective.pub\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCiCwJYgzsf+Z4IPhjFipM968JAik36ipxAlxcbVgEiNp6W1+RSuc58b3aVOsx9lZPwESDPRzUo/uqSfR0ZdPVoF3ie2QP2HE3P3PrPpDpsQ2BNonsOWXIfCfgSABNvPz9YK2jXLQCC6O4FhdmUaGtR478h7G4W8IaWh6CrgQJFMfyal2a2CgIJzaHd7+6ihWJydRBdIUEqR7EurdRO3sGZ+mQZDXyKRnrY9RXSmRpDJci7jdfbGUauQ3IQhXVhEhweRDaNmBf94uQ5OnObQ/0haKlPYbcrmEA8YXt5V2Oz4QXchZuCskg1lvH6WK2DdwFJq8A7Mxnl73mJ0hurw5s5 dtk22@dtk22-25\n\nEOF\n\ncat << EOF > /etc/mcollective/ssh/authorized_keys\nssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOWu0cXOSM8wE/1O2fMCKR7ve4BkYExqpM2SvJgLiW7SMkcNfnPLl4foa3uQPVqHX3YkhrrUIda4P53QWK7CQcqLqUeybURrH1ZyLOhABCfxQebazrac3E0GbEEkuVUplAd0ThkrdFFTy8vL5BnjcLY7cdjSDEFhrCojzPCI6QmnSWmDjJ7D9hY9GOwZzqBFxiiD0cgUZrtUvRghd/w/UUqxbPOAPWrujN/Jmc+16Zw8WMTW45LrtUc2XnK6epPFhvP2rEGPIEsg6a2l4ViWvRqZlOp0x3EqvsHGSFZaiK5/EmR3qj2A2jzg89heaCvBHO+9Z4YUr7D3Hu/32/p/j3 dtk22@dtk22-25\n\nEOF\n\nssh-keygen -f \"/root/.ssh/known_hosts\" -R ec2-54-226-228-161.compute-1.amazonaws.com\ncat << EOF >>/root/.ssh/known_hosts\n|1|opT8ph2zsOk1aNNxsrVPZr2I/Jo=|V443cfBsN3Uh/pUUixyOu4T/C1Q= ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcNFXOld8aRO+hYOL/F5AnoN0A4b16OVWRk6PMZVUAiPeZ2cFsIbkCgELByazyyEVjs5PlfLfgU1IqjEeFF7kDaj/f9GXCjuxGWAEBkbqzJ3nW7iPBPCm+0jPbNLD+s2boAKeGp1jDS5h5SANhbaale1kSLo3+MqGn5A69Pt+nO4KTZkYh2h7jHM5D7fY297x07MJbPyzC/KergY22TkP7P1BfLzDDrVLrvz++6YSbMAOrY7OSY/vl1hdI4Z4yQMlFHvLZ+SYbA76Y0jndW7ooLaBlQEYarEu1BtYPZ2F+CrivUb4MzmEZ0I2vxMegDwHJ13pQy6sfX0aungfUyk1H\n\nEOF\n\n\n/etc/init.d/mcollective* restart\n\n\n"

EM.run do
  user = 'ubuntu'
  password = '1ubuntu'

  host1 = 'ec2-54-80-131-119.compute-1.amazonaws.com'
  host2 = 'ec2-54-225-38-127.compute-1.amazonaws.com'
  host3 = 'ec2-54-227-229-14.compute-1.amazonaws.com'

  # process multiple SSH connections in parallel
  connections = [
    EM::Ssh.start(host1, user, password: password),
    EM::Ssh.start(host2, user, password: password),
    EM::Ssh.start(host3, user, password: password)
  ]

  connections.each do |connection|
    conn_host = connection.host

    connection.errback do |err|
      $stderr.puts "#{err} (#{err.class})"
      # EM.stop
      puts "[ERROR] Unable to connect to host '#{conn_host}'!"
      connections.delete(connection)
    end

    connection.callback do |ssh|
      install_script_file_path = nil
      upload_error = false

      ssh.exec!('rm -rf /tmp/dtk-node-agent') do |_channel, stream, data|
        puts "#{conn_host}: #{data}" if stream == :stdout
      end

      begin
        install_script_file = Tempfile.new('install_script')
        install_script_file.write(InstallScriptContent)
        install_script_file.close
        install_script_file_path = install_script_file.path

        # getting home path on unix system, we will use R8.app_user_home() in code
        home_path = Etc.getpwuid(Process.uid).dir

        # executing upload commands
        Net::SCP.upload!(conn_host, user, install_script_file.path, '/tmp', ssh: { password: password, port: '22' }, recursive: true)
        Net::SCP.upload!(conn_host, user, "#{home_path}/dtk-node-agent", '/tmp', ssh: { password: password, port: '22' }, recursive: true)
      rescue Exception => e
        puts "\n[ERROR] Error occured in SCP.upload to host '#{conn_host}': #{e}.\n"
        puts '[ERROR] Rest of the commands will not be executed on this host!'
        upload_error = true
      ensure
        install_script_file.unlink
      end

      # if error, do not proceed with execution for specific host
      if upload_error
        connections.delete(connection)
      else
        install_command = user.eql?('root') ? 'bash /tmp/dtk-node-agent/install_agent.sh' : 'sudo bash /tmp/dtk-node-agent/install_agent.sh'
        ssh.exec!(install_command) do |_channel, stream, data|
          puts "#{conn_host}:#{data}" if stream == :stdout
        end

        ssh.exec!('rm -rf /tmp/dtk-node-agent') do |_channel, _stream, data|
          puts "#{conn_host}: #{data}" #if stream == :stdout
        end

        install_script_command = user.eql?('root') ? "bash #{install_script_file_path}" : "sudo bash #{install_script_file_path}"
        ssh.exec!(install_script_command) do |_channel, stream, data|
          puts "#{conn_host}: #{data}" if stream == :stdout
        end

        ssh.exec!("rm -rf #{install_script_file_path}") do |_channel, stream, data|
          puts "#{conn_host}: #{data}" if stream == :stdout
        end

        puts "\n[INFO] '#{conn_host}' COMPLETED SUCCESSFULLY!"
        connections.delete(connection)
      end

      if connections.empty?
        ssh.close
        EM.stop
      end
    end
  end
end
