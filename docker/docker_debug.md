Open a shell inside the container:
```
docker exec -it dtk bash
```

switch to `dtk1` user and cd to server code:
```
su - dtk1
cd ~/server/current
```

install debugger and dev dependencies:
```
rvmsudo gem install debugger
rvmsudo bundle install --with development
```

add the remote debugger snippet to the code you want to debug:
```
   require 'debugger'
   Debugger.wait_connection = true
   Debugger.start_remote
   debugger
```

trigger the passenger reload:
```
touch application/tmp/restart.txt
```

Next request will reload passenger and the execution will stop at the debugger statement
until `rdebug -c` is executed (also inside the docker container).
