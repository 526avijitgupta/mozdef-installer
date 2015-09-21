MOZ_PATH=/opt/MozDef

# Cloning into /opt/
git clone git@github.com:jeffbryner/MozDef.git $MOZ_PATH

# Rabbit MQ
sudo apt-get install -y rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management

# MongoDB
sudo apt-get install -y mongodb

# Nodejs and NPM
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install -y nodejs npm

# Nginx
sudo apt-get install -y nginx-full
sudo cp /opt/MozDef/docker/conf/nginx.conf /etc/nginx/nginx.conf

# MozDef
sudo apt-get install -y python2.7-dev python-pip curl supervisor wget libmysqlclient-dev
sudo pip install -U pip

# Below may have to be installed globally
sudo pip install uwsgi celery virtualenv
PATH_TO_VENV=$HOME/.mozdef_env
# Creating a virtualenv here
virtualenv $PATH_TO_VENV

sudo mkdir /var/log/mozdef
sudo mkdir -p /run/uwsgi/apps/
sudo touch /run/uwsgi/apps/loginput.socket && sudo chmod 666 /run/uwsgi/apps/loginput.socket
sudo touch /run/uwsgi/apps/rest.socket && sudo chmod 666 /run/uwsgi/apps/rest.socket

# Rewrite the below line, special care to be taken
mkdir -p $PATH_TO_VENV/bot/ && cd $PATH_TO_VENV/bot/

# Where to put it ? What does it do ? Currently goes to $PATH_TO_VENV/bot --- Explicit path to be defined
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && gzip -d GeoLiteCity.dat.gz

# Copying config files

#### Do we need to do this ??
sudo cp $MOZ_PATH/docker/conf/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
####

sudo cp $MOZ_PATH/docker/conf/settings.js $MOZ_PATH/meteor/app/lib/settings.js
sudo cp $MOZ_PATH/docker/conf/config.py $MOZ_PATH/alerts/lib/config.py
sudo cp $MOZ_PATH/docker/conf/sampleData2MozDef.conf $MOZ_PATH/examples/demo/sampleData2MozDef.conf
sudo cp $MOZ_PATH/docker/conf/mozdef.localloginenabled.css $MOZ_PATH/meteor/public/css/mozdef.css

# Install elasticsearch
# Instead of copying conf, lets see if its needed
# elasticsearch.yml is to be copied or edited manually, how about adding echo "" >> elasticsearch.yml
# sudo cp docker/conf/elasticsearch.yml /opt/elasticsearch-1.3.2/config/
# ElasticSearch to be installed by a different shell script

# Install Kibana
cd /tmp/
curl -L https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz | tar -C /opt -xz
/bin/ln -s /opt/kibana-3.1.0 /opt/kibana
cd /opt/
## Instead of downloading: How about copying from a to b
sudo wget https://raw.githubusercontent.com/jeffbryner/MozDef/master/examples/kibana/dashboards/alert.js
sudo wget https://raw.githubusercontent.com/jeffbryner/MozDef/master/examples/kibana/dashboards/event.js
sudo cp alert.js /opt/kibana/app/dashboards/alert.js
sudo cp event.js /opt/kibana/app/dashboards/event.js

# For Meteor, try to avoid symlink
curl -L https://install.meteor.com/ | /bin/sh
sudo npm install -g meteorite
ln -s /usr/bin/nodejs /usr/bin/node
cd $MOZ_PATH/meteor
#meteor

#======================================================#
# THE BELOW SHOULD BE IN A DIFFERENT SHELL SCRIPT      #
#======================================================#

#
# For Starting the services
#

# RabbitMQ
sudo service rabbitmq-server start

# Elasticsearch
sudo service elasticsearch start

# Nginx
sudo service nginx start

##
## NEED TO ADD THE VIRTUALENV PATH: -H /path/to/virtualenv
##
# Loginput
cd /opt/MozDef/loginput
sudo /usr/local/bin/uwsgi --socket /run/uwsgi/apps/loginput.socket --wsgi-file $MOZ_PATH/loginput/index.py --buffer-size 32768 --master --listen 100 --uid root --pp /opt/MozDef/loginput --chmod-socket --logto /var/log/mozdef/uwsgi.loginput.log -H $PATH_TO_VENV

# Rest
cd /opt/MozDef/rest
sudo /usr/local/bin/uwsgi --socket /run/uwsgi/apps/rest.socket --wsgi-file $MOZ_PATH/rest/index.py --buffer-size 32768 --master --listen 100 --uid root --pp /opt/MozDef/rest --chmod-socket --logto /var/log/mozdef/uwsgi.rest.log -H $PATH_TO_VENV
# ES Worker
cd /opt/MozDef/mq
sudo /usr/local/bin/uwsgi --socket /run/uwsgi/apps/esworker.socket --mule=esworker.py --mule=esworker.py --buffer-size 32768 --master --listen 100 --uid root --pp /opt/MozDef/mq --stats 127.0.0.1:9192 --logto /var/log/mozdef/uwsgi.esworker.log --master-fifo /run/uwsgi/apps/esworker.fifo -H $PATH_TO_VENV

# Meteor
cd /opt/MozDef/meteor
meteor

# Alerts
cd /opt/MozDef/alerts
sudo celery -A celeryconfig worker --loglevel=info --beat

#==========================================#
# Eligible to come in installation script  #
#==========================================#

# Injecting sample data
python $MOZ_PATH/examples/es-docs/inject.py

# Helper Jobs

# Health/status
## Do look at the source code #TODO
sh $MOZ_PATH/examples/demo/healthjobs.sh

# Real Time Events
## Do look at the source code #TODO
sh $MOZ_PATH/examples/demo/sampleevents.sh

# Real Time Alerts
## Do look at the source code #TODO
sh $MOZ_PATH/examples/demo/syncalerts.sh
