## DTK Server

What it is?
--------------
DTK Server is a Ruby based application that handles requests from DTK Client and sends requests to DTK Repoman. It manages tenant users, installed and imported component and servie modules, creates and converges service instances and performs all node orchestration. 


##Usage
-------------
## Deploying DTK Server with Docker
___  
Fastest way to deploy  DTK Server is with a Docker container. Docker image [getdtk/dtk-server](https://hub.docker.com/r/getdtk/dtk-server/) contains all required services and components for deploying DTK Server.

#### Preparation
- Install Docker   
 
- Pull the latest DTK Server Docker image with `docker pull getdtk/dtk-server`

- Select a container root directory on host which will be used by the Docker container for persistence (e.g. `/usr/share/docker/dtk`), and create `dtk.config` (e.g. `/usr/share/docker/dtk/dtk.config`) with following content:

   ```
USERNAME=dtk-user
PASSWORD=somepassword
PUBLIC_ADDRESS=someinstance.dtk.io
INSTANCE_NAME=dtk1
   ```  

#### Starting the container
Next step is to start the docker container with the directory from above used as a volume. The Docker container requires some ports to be forwared, for example: HTTP, ActiveMQ and SSH port. Example of starting a Docker container:  
   
```
docker run --name dtk -v /usr/share/docker/dtk:/host_volume -p 8080:80 -p 6163:6163 -p 2222:22 -d getdtk/dtk-server  
```
#### Connecting to DTK Server Docker container

After the container is up and running (will take a minute on the first start), you can connect to it via [dtk-client](https://github.com/rich-reactor8/dtk-client), by running either `dtk` or `dtk-shell` command.

In the DTK Client prompt you can enter the values set in `dtk.config` (username, password and instance address).   

Unless you have SSL, after the prompt, values for `secure_connection` and `http_port` in `~/dtk/client.conf` should be changed to `false` and forwared http port values respectively.  


Note that if you need to forward GIT SSH port to a different one, you can use the `-e GIT_PORT=<desired_port>`.

##### Upgrading the container
To upgrade DTK container to a newer version, execute the following commands:

```
docker pull getdtk/dtk-server # pull the latest image 
docker stop dtk # stop the running container
docker rm dtk # remove the container, container data will be perserved in container root directory 
docker run --name dtk -v /usr/share/docker/dtk:/host_volume -p 8080:80 -p 6163:6163 -p 2222:22 -d getdtk/dtk-server # start the container 
```

___

## License

dtk-server is copyright (C) 2010-2016 dtk contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this work except in compliance with the License.
You may obtain a copy of the License in the [LICENSE](LICENSE) file, or at:

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
