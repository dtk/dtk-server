module XYZ
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      def self.execute(task_idh,top_task_idh,task_action)
        node = task_action[:node]
        external_ref = node[:external_ref]||{}
        instance_id = external_ref[:instance_id]

        if instance_id.nil?
          ami = external_ref[:image_id]
          unless ami
            raise Error.new("cannot find ami")
          end
          raise ErrorCannotCreateNode.new unless ami
          flavor_id = external_ref[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size] 
          create_options = {:image_id => ami,:flavor_id => flavor_id}

          create_options.merge!(:groups => external_ref[:security_group_set]||DefaultSecurityGroupSet)
          #TODO: patch
          create_options.merge!(:key_name => "rich-east")
          avail_zone = external_ref[:availability_zone]
          unless avail_zone.nil? or avail_zone == "automatic"
            create_options.merge!(:availability_zone => avail_zone)
          end
          unless create_options.has_key?(:user_data)
            user_data = default_user_data()
            create_options[:user_data] = user_data if user_data
          end
          response = conn().server_create(create_options)
          instance_id = response[:id]
          state = response[:state]
          external_ref = external_ref.merge({
            :instance_id => instance_id,
            :type => "ec2_instance"
          })
          Log.info("#{node_print_form(node)} with ec2 instance id #{instance_id}; waiting for it to be available")
          node_update_hash = {
            :external_ref => external_ref,
            :type => "instance",
            :is_deployed => true,
            :operational_status => "starting"
          }
          node.merge!(node_update_hash)
          node.update(node_update_hash)
        else
          Log.info("node already created with instance id #{instance_id}; waiting for it to be available")
        end
        {:status => "succeeded",
          :node => {
            :external_ref => external_ref
          }
        }
      end
      class << self
       private 
        #TODO: stub
        #TODO: need sto be cased on os type; below assumes that ubuntu cloud-init being used
        def default_user_data()
          if git_server_url = RepoManager.repo_url()
            git_server_dns = RepoManager.repo_server_dns()
            #TODO: to make more secure when gitserver different from this server will assume footprint put on server at installtime
            footprint = `ssh-keyscan -H -t rsa #{git_server_dns}`
            UserDataTemplate.result(:git_server_url => git_server_url, :git_server_dns => git_server_dns,:footprint => footprint)
          end
        end
      end
#TODO: put this as boothook because if not get race condition with start of mcollective
#need to check if this now runs on every boot; if so might want to put provision in so only runs on first boot
UserDataTemplate = Erubis::Eruby.new <<eos
#cloud-boothook
#!/bin/sh 

cat << EOF > /etc/mcollective/facts.yaml
---
git-server: "<%=git_server_url %>"
EOF

ssh-keygen -f "/root/.ssh/known_hosts" -R <%=git_server_dns %>
cat << EOF >>/root/.ssh/known_hosts
<%=footprint %>
EOF

eos
#TODO: when put apt-get update in thing delying time it taks for the os to say it is ready /usr/bin/apt-get update
      DefaultSecurityGroupSet = ["default"] 
      #destroys the node if it exists
      def self.destroy_node?(node)
        instance_id = (node[:external_ref]||{})[:instance_id]
        return true unless instance_id #return if instance does not exist
        response = conn().server_destroy(instance_id)
        Log.info("operation to destroy ec2 instance #{instance_id} had response: #{response.to_s}")
        response
      end

      def self.get_node_state(node)
        instance_id = (node[:external_ref]||{})[:instance_id]
        unless instance_id
          Log.error("get_node_state called when #{node_print_form(node)} does not have instance id")
          return nil
        end
        conn().server_get(instance_id)
      end

      def self.get_node_operational_status(node)
        instance_id = (node[:external_ref]||{})[:instance_id]
        unless instance_id
          Log.error("get_node_state called when #{node_print_form(node)} does not have instance id")
          return nil
        end
        #TODO: see if more targeted get to just get operational status
        state = conn().server_get(instance_id)
        op_status = state && state[:state]
        StateTranslation[op_status] || op_status
      end
      StateTranslation = {
        "pending" => "starting",
        "shutting-down" => "stopping"
      } 

      def self.node_print_form(node)
        "#{node[:display_name]} (#{node[:id]}"
      end

      #TODO: sharing ec2 connection with ec2 datasource
      def self.conn()
        Conn[0] ||= CloudConnect::EC2.new
      end
      Conn = Array.new
    end
  end
end
