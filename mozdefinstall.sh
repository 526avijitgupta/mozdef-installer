# Cloning into /opt/ (Will require root permission to clone)
cd /opt/
git clone git@github.com:jeffbryner/MozDef.git
sudo chmod -R 755 MozDef

# Rabbit MQ
sudo apt-get install -q -y rabbitmq-server
sudo rabbitmq-plugins enable rabbitmq_management

# MongoDB
sudo apt-get install -q -y mongodb

# Nodejs and NPM
curl -sL https://deb.nodesource.com/setup_0.12 | sudo bash -
sudo apt-get install -q -y nodejs npm

# Nginx
sudo apt-get install -q -y nginx-full
# sudo cp conf/nginx.conf /etc/nginx/nginx.conf

# MozDef
sudo apt-get install -q -y python2.7-dev python-pip curl supervisor wget libmysqlclient-dev
sudo pip install -U pip

cd /opt/MozDef
##
## Use source ~/envs/mozdef/bin/activate (With the exact path)
##
#sudo pip install virtualenvwrapper
#mkvirtualenv mozdef
pip install -r requirements.txt
pip install uwsgi celery

# Clone repo into /opt/MozDef
# pip install -r requirements (of Mozdef) into virtualenv

# Use sudo here
mkdir /var/log/mozdef
mkdir -p /run/uwsgi/apps/
touch /run/uwsgi/apps/loginput.socket && chmod 666 /run/uwsgi/apps/loginput.socket
touch /run/uwsgi/apps/rest.socket && chmod 666 /run/uwsgi/apps/rest.socket

# Rewrite the below line, special care to be taken
mkdir -p /home/mozdef/envs/mozdef/bot/ && cd /home/mozdef/envs/mozdef/bot/

# Where to put it ? What does it do ?
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && gzip -d GeoLiteCity.dat.gz

##
## Copy various conf files
##

# Install elasticsearch
# Copy elasticsearch.yml from conf

# Install Kibana
# Copy JS files as given in dockerfile

# For Meteor, try to avoid symlink
curl -L https://install.meteor.com/ | /bin/sh
npm install -g meteorite
ln -s /usr/bin/nodejs /usr/bin/node
cd /opt/MozDef/meteor


#
# For Starting the services
#

# RabbitMQ
sudo /etc/init.d/rabbitmq-server start

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
