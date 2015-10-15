## DTK Server

### Installation

Under development.

### Setup

Under development.

## DEV GUIDE

Following are snippets that will introudce you to basic user of system and it's code base

#### DTK ORM
##### Getting default project

	default_project = Project.get_all(ModelHandle.new(c = 2, :project)).first

##### SELECT from DB


	Model.get_objs(default_project.model_handle(:user), { :cols => User.common_columns })


##### UPDATE from DB

  users = ::DTK::Model.get_objs(default_project.model_handle(:user), { :cols => [:id, :password] })

  users.each do |user|
    user[:password] = ::DTK::DataEncryption.hash_it(user[:password])
  end

  ::DTK::Model.update_from_rows(default_project.model_handle(:user), users)

### Running the docker image  
Select a directory on host which will be used by the docker container for persistance (e.g. `/dtk`), and populate a `dtk.config` inside it (e.g. `/dtk/dtk.config`):  
```
USERNAME=someuser
PASSWORD=somepassword
PUBLIC_ADDRESS=someinstance.dtk.io
INSTANCE_NAME=someinstance
```   
Next step is to start the docker container with the directory from above used as a volume:  
```
docker run --name dtk -v /dtk:/host_volume -p 8080:80 -p 6163:6163 -p 2222:22 -d getdtk/server-full
```  
After the container is up and running (will take a minute on the first start) you can connect to it via [dtk-client](https://github.com/rich-reactor8/dtk-client) using the same values as set in `dtk.config`.  
Note that if you need to forward GIT SSH port to a different one, you can use the `-e GIT_PORT=2200` switch for example. 
##### Upgrading the container
To upgrade a running container with a newer image run:  
```  
docker pull getdtk/server-full
docker stop dtk
docker rm dtk
docker run --name dtk -v /dtk:/host_volume -p 8080:80 -p 6163:6163 -p 2222:22 -d getdtk/server-full
```
### Connecting to Tenant inside container
To connect to the tenant inside the docker container, you will have to set `secure_connection` to `false` in the dtk/client.conf file of the dtk-client directory and run the `dtk-shell` command. For the server address, tenant username and password, enter the same values that are set in the `dtk.config` file of the docker container host volume.