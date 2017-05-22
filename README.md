## Dtk Server

What it is?
--------------
Dtk Server is a Ruby based application that handles requests from Dtk Client and sends requests to Dtk Repoman. It manages tenant users, installed and imported component and servie modules, creates and converges service instances and performs all node orchestration.


## Usage
-------------
## Deploying Dtk Server with Docker
___
Fastest way to deploy  Dtk Server is with a Docker container. Docker image [getdtk/dtk-server](https://hub.docker.com/r/getdtk/dtk-server/) contains all required services and components for deploying Dtk Server.

#### Preparation
- [Install Docker](https://docs.docker.com/engine/installation/)

- Pull the latest Dtk Server Docker image with `docker pull getdtk/dtk-server`

- Select a container root directory on host which will be used by the Docker container for persistence (e.g. `/usr/share/docker/dtk`), and create `dtk.config` (e.g. `/usr/share/docker/dtk/dtk.config`) with following content:

      USERNAME=dtk-user
      PASSWORD=somepassword
      PUBLIC_ADDRESS=<public address of the docker host>
      ## optionally set git user and email for install-client.sh script
      # GIT_EMAIL=
      # GIT_USER=


More information about the dtk.config file can be found in [dtk.config.example](dtk.config.example)

#### Starting the container
Next step is to start the docker container with the directory from above used as a volume. The Docker container requires some ports to be forwared, for example: HTTP, ActiveMQ and SSH port. Example of starting a Docker container:

```
docker run --name dtk -v /usr/share/docker/dtk:/host_volume -p 8080:80 -p 6163:6163 -p 2222:22 -d getdtk/dtk-server
```

This will pull the latest Dtk Server Docker image that was built.

Example of starting a Dtk Server Docker container from a tagged Docker image.

```
docker run --name dtk -v /usr/share/docker/dtk:/host_volume -p 8080:80 -p 6163:6163 -p 2222:22 -d getdtk/dtk-server:v0.9.0
```

#### Alternate one-line server bootstrap
This command will automate all of the steps from above:  
```
\curl -sSL https://getserver.dtk.io | bash -s /usr/share/docker/dtk
```

#### Connecting to Dtk Server Docker container

After the container is up and running (will take a minute on the first start), you can connect to it via [dtk-client](https://github.com/rich-reactor8/dtk-client), by running either `dtk` or `dtk-shell` command.

In the Dtk Client prompt you can enter the values set in `dtk.config` (username, password and instance address).

Unless you have SSL, after the prompt, values for `secure_connection` and `http_port` in `~/dtk/client.conf` should be changed to `false` and forwared http port values respectively.


Note that if you need to forward GIT SSH port to a different one, you can use the `-e GIT_PORT=<desired_port>`.

### Installing Dtk Client
Assuming the docker container was started as described above, Dtk Client can be installed and configured automatically running the [install-client.sh](https://raw.githubusercontent.com/dtk/dtk-server/master/install-client.sh) script:
```
./install-client.sh [-u user] [-p port] configuration_path

configuration_path   - location of dtk.config file
user                 - user on which to install and configure dtk-client
                       defaults to new user named 'dtk-client
port                 - port where Dtk server is listening
                       defaults to 8080
```

#### Alternate one-line client install
This command will invoke the script from above directly:  
```
\curl -sSL https://getclient.dtk.io | bash -s /usr/share/docker/dtk
```

##### Upgrading the container
To upgrade Dtk container to a newer version, execute the following commands:

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
