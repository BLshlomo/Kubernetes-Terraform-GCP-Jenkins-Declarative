#!/bin/bash
apt-get install software-properties-common -y
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
   $(lsb_release -cs) \
   stable"
apt-get update -y
apt-get -y install docker-ce
curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)"\
   -o /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/1.26.2/contrib/completion/bash/docker-compose\
   -o /etc/bash_completion.d/docker-compose
chmod +x /usr/local/bin/docker-compose
#ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
#groupmod -g 998 docker
usermod -aG docker jenkins
usermod -aG docker bitnami