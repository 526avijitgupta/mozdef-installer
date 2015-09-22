init:
	./mozdefinstall_trial.sh

install_req:
	source install_req.sh

start:
	sudo service rabbitmq-server start
	sudo service elasticsearch start
	sudo service nginx start
	cd /opt/MozDef/meteor && meteor run
