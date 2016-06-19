#!/bin/bash
echo "####################################"
echo "###  UPDATE AND INSTALL PROGRAMS ###"
echo "####################################"
#      sudo apt-get update

      DOCKER_INSTALLED=$(whereis docker | grep docker | cut -d ':' -f 2 )
      if [ "$DOCKER_INSTALLED" == "" ]; then
        wget -qO- https://get.docker.com/ | sh
        sudo usermod -aG docker vagrant
      fi

      GIT_INSTALLED=echo $(apt-cache policy git | grep Installed | cut -d ':' -f 2 | cut -d '(' -f 2 | cut -d ')' -f 1 | tr -d ' ')
      if [ "$GIT_INSTALLED" == "none" ]; then
        apt-get install -y git
      fi

echo "####################################"
echo "###  PULL DOCKER IMAGES          ###"
echo "####################################"
      docker pull consul
      docker pull cimpress/git2consul

      docker ps -a | grep consul | awk '{print $1 }' | xargs -I {} docker rm -f {}
      docker run -d -p 8400:8400 -p 8500:8500 -p 8600:53/udp --name node1 -h node1 consul agent -dev -client=0.0.0.0 -data-dir /tmp/consul

      CONSUL_IP=$(ifconfig eth0 | grep 'inet\ addr:' | cut -d ':' -f 2 | cut -d 'B' -f 1 | tr -d ' ')

      docker ps -a | grep git2consul | awk '{print $1 }' | xargs -I {} docker rm -f {}

      mkdir /tmp/git2consul.d/
      cp -f /vagrant/git2consul.json /tmp/git2consul.d/config.json

      docker run -d --name git2consul -v /tmp/git2consul.d:/etc/git2consul.d cimpress/git2consul --endpoint $CONSUL_IP --port 8500 --config-file /etc/git2consul.d/config.json

      docker ps -a

      docker logs git2consul
