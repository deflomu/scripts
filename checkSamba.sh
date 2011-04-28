#!/bin/sh

SAMBA_RUNNING=`ps|grep smbd|grep -v grep|wc -l`;

if [ $SAMBA_RUNNING == 0 ]; then
	logger -t checkSamba Samba seems not to be running. Saving Log...
	logread > /etc/automatic/SambaDidNotRun.log
	fs -l RestartSamba;
fi;
