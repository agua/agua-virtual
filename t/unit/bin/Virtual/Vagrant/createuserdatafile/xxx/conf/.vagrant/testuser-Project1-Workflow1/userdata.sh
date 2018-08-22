#!/bin/bash

echo "userdata"
echo `hostname`
echo `date`

export INSTALLDIR=/a/t/unit/bin/Virtual/Vagrant/createuserdatafile/xxx
echo "INSTALLDIR: $INSTALLDIR"
export BASEDIR=/data/vagrant/ubuntu
echo "BASEDIR: $BASEDIR"

logfile="/home/ubuntu/worker.log"
sudo rm -fr $logfile
exec > >(tee $logfile ) 2>&1

#### MOUNT /data
mkdir /data
mount /dev/xvdb /data

#### FIX HOSTNAME
echo "Fixing hostname" 
sudo echo "127.0.0.1 `facter hostname`" &>> /etc/hosts;

#### FIX PERMISSIONS
echo "Fixing permissions" 
sudo chown -R ubuntu:ubuntu /data /tmp;
ls -al /data;

#### SET GIT IDENTITY
git config --global user.email "stuartpyoung@gmail.com"
git config --global user.name "Stuart Young"

#### UPDATE dnaseq
echo "Updating dnaseq" 
sudo chown -R ${USER} /a/apps/dnaseq/.git 
cd /a/apps/dnaseq; sudo git pull origin dev

#### UPDATE agua
echo "Updating agua" 
cd /a; sudo rm -fr bin/install/resources
cd /a; sudo git stash save changes 
cd /a; sudo git pull origin dev

#### SET ENVARS
echo "Setting envars" 
source /a/apps/dnaseq/envars.sh;

#### START DAEMONS
/a/bin/install/resources/agua/install/listener.sh
/a/bin/install/resources/agua/install/monitor.sh