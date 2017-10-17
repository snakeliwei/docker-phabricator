#!/bin/sh

#if 'php', 'task', 'pull', 'etc'... else write out and/or execute command
if [ "$@" == "FPM" ]; then
	if [ -d "/srv/phabricator" ]; then
		echo 'Updating phabricator'
		
		git config --global user.email "you@example.com"
		git config --global user.name "Your Name"
		
		git -C /srv/libphutil pull
		git -C /srv/arcanist pull
		
		git -C /srv/phabricator stash
		git -C /srv/phabricator pull
		git -C /srv/phabricator stash pop

		echo 'Finished updating phabricator'
	else
		echo 'Cloning phabricator from source'
		
		git clone -b stable https://github.com/phacility/libphutil.git /srv/libphutil
		git clone -b stable https://github.com/phacility/arcanist.git /srv/arcanist
		git clone -b stable https://github.com/phacility/phabricator.git /srv/phabricator
		
		# Allow daemon to run foreground
		sed -i "s/\['daemonize'\] = true/\['daemonize'\] = false/g" /srv/phabricator/src/applications/daemon/management/PhabricatorDaemonManagementWorkflow.php
		echo 'Finished cloning phabricator'
		
		echo 'Synching DB pasword'
		sed -i "s/\"mysql.pass\": \"[^\"]*\",/\"mysql.pass\": \"$MYSQL_ROOT_PASSWORD\",/g" /local.json
		
		cp /local.json /srv/phabricator/conf/local/local.json
	fi

	echo 'Upgrading database schema'
	/srv/phabricator/bin/storage upgrade --force
	
	echo 'Bootup Complete'
	exec php-fpm7 -FR
fi

if [ "$@" == "PULL" ]; then
	echo 'Waiting for configuration'
	while [ ! -e /srv/phabricator/conf/local/local.json ]; do
		wait 1
	done
	echo 'Bootup Complete'
	exec /srv/phabricator/bin/phd launch PhabricatorRepositoryPullLocalDaemon
fi

if [ "$@" == "TASK" ]; then
	echo 'Waiting for configuration'
	while [ ! -e /srv/phabricator/conf/local/local.json ]; do
		wait 1
	done
	echo 'Bootup Complete'
	exec /srv/phabricator/bin/phd launch PhabricatorTaskmasterDaemon
fi

if [ "$@" == "TRIG" ]; then
	echo 'Waiting for configuration'
	while [ ! -e /srv/phabricator/conf/local/local.json ]; do
		wait 1
	done
	echo 'Bootup Complete'
	exec /srv/phabricator/bin/phd launch PhabricatorTriggerDaemon
fi

echo "Start container with 'FPM', 'PULL', 'TASK' or 'TRIG' to start the appropriate daemon"
exec "$@"