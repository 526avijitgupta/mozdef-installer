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

# Where to put it ? What does it do ?
wget http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz && gzip -d GeoLiteCity.dat.gz

# Copying config files

#### Do we need to do this ??
sudo cp $MOZ_PATH/docker/conf/supervisor.conf /etc/supervisor/conf.d/supervisor.conf
####

sudo cp $MOZ_PATH/docker/conf/settings.js $MOZ_PATH/meteor/app/lib/settings.js
sudo cp $MOZ_PATH/docker/conf/config.py $MOZ_PATH/alerts/lib/config.py
sudo cp $MOZ_PATH/docker/conf/sampleData2MozDef.conf $MOZ_PATH/examples/demo/sampleData2MozDef.conf
sudo cp $MOZ_PATH/docker/conf/mozdef.localloginenabled.css $MOZ_PATH/meteor/public/css/mozdef.css
