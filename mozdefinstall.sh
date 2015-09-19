# Cloning into /opt/
cd /opt/
sudo git clone git@github.com:jeffbryner/MozDef.git
sudo chmod -R 755 MozDef
cd /opt/MozDef/

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
sudo cp docker/conf/nginx.conf /etc/nginx/nginx.conf

# MozDef
sudo apt-get install -y python2.7-dev python-pip curl supervisor wget libmysqlclient-dev
sudo pip install -U pip

##
## Use source ~/envs/mozdef/bin/activate (With the exact path)
##
# sudo pip install virtualenvwrapper
# mkvirtualenv mozdef
pip install -r requirements.txt
pip install uwsgi celery

sudo mkdir /var/log/mozdef
sudo mkdir -p /run/uwsgi/apps/
sudo touch /run/uwsgi/apps/loginput.socket && sudo chmod 666 /run/uwsgi/apps/loginput.socket
sudo touch /run/uwsgi/apps/rest.socket && sudo chmod 666 /run/uwsgi/apps/rest.socket

# Rewrite the below line, special care to be taken
mkdir -p /home/mozdef/envs/mozdef/bot/ && cd /home/mozdef/envs/mozdef/bot/

# Where to put it ? What does it do ?
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && gzip -d GeoLiteCity.dat.gz


cd /opt/MozDef/
sudo cp docker/conf/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
sudo cp docker/conf/settings.js /opt/MozDef/meteor/app/lib/settings.js
sudo cp docker/conf/config.py /opt/MozDef/alerts/lib/config.py
sudo cp docker/conf/sampleData2MozDef.conf /opt/MozDef/examples/demo/sampleData2MozDef.conf
sudo cp docker/conf/mozdef.localloginenabled.css /opt/MozDef/meteor/public/css/mozdef.css

# Install elasticsearch
cd /tmp/
curl -L https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.tar.gz | tar -C /opt -xz
cd /opt/
sudo cp docker/conf/elasticsearch.yml /opt/elasticsearch-1.3.2/config/

# Install Kibana
cd /tmp/
curl -L https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz | tar -C /opt -xz
cd /opt/
sudo wget https://raw.githubusercontent.com/jeffbryner/MozDef/master/examples/kibana/dashboards/alert.js
sudo wget https://raw.githubusercontent.com/jeffbryner/MozDef/master/examples/kibana/dashboards/event.js
sudo cp alert.js /opt/kibana/app/dashboards/alert.js
sudo cp event.js /opt/kibana/app/dashboards/event.js

# For Meteor, try to avoid symlink
curl -L https://install.meteor.com/ | /bin/sh
npm install -g meteorite
ln -s /usr/bin/nodejs /usr/bin/node
cd /opt/MozDef/meteor


#
# For Starting the services
#

# RabbitMQ
sudo service rabbitmq-server start

# Elasticsearch
sudo service elasticsearch start

# Nginx
sudo service nginx start

# Loginput
cd /opt/MozDef/loginput
sudo /usr/local/bin/uwsgi --socket /run/uwsgi/apps/loginput.socket --wsgi-file index.py --buffer-size 32768 --master --listen 100 --uid root --pp /opt/MozDef/loginput --chmod-socket --logto /var/log/mozdef/uwsgi.loginput.log

# Rest
cd /opt/MozDef/rest
sudo /usr/local/bin/uwsgi --socket /run/uwsgi/apps/rest.socket --wsgi-file index.py --buffer-size 32768 --master --listen 100 --uid root --pp /opt/MozDef/rest --chmod-socket --logto /var/log/mozdef/uwsgi.rest.log

# ES Worker
cd /opt/MozDef/mq
sudo /usr/local/bin/uwsgi --socket /run/uwsgi/apps/esworker.socket --mule=esworker.py --mule=esworker.py --buffer-size 32768 --master --listen 100 --uid root --pp /opt/MozDef/mq --stats 127.0.0.1:9192 --logto /var/log/mozdef/uwsgi.esworker.log --master-fifo /run/uwsgi/apps/esworker.fifo

# Meteor
cd /opt/MozDef/meteor
meteor

# Alerts
cd /opt/MozDef/alerts
sudo celery -A celeryconfig worker --loglevel=info --beat

# Injecting sample data
cd /opt/MozDef/examples/es-docs/
python inject.py

# Helper Jobs

# Health/status
## Do look at the source code #TODO
sh /opt/MozDef/examples/demo/healthjobs.sh

# Real Time Events
## Do look at the source code #TODO
sh /opt/MozDef/examples/demo/sampleevents.sh

# Real Time Alerts
## Do look at the source code #TODO
sh /opt/MozDef/examples/demo/syncalerts.sh
