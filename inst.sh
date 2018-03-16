#!/bin/bash

WORKDIR=/data/letsencrypt
DOMAIN="domain.ddnss.de"
DDNSS_Token="ddnsstoken"

#Check if socat is installed
#SOCAT=/usr/bin/socat     
#if [ -f $SOCAT ]; then
#   echo "File $SOCAT exists."
#else
#  echo "File $SOCAT does not exist. installing it"
#  apt-get intall socat
	
#fi

#Create Workdir and Backup Folder for orig. SSL Certs
if [ -d $WORKDIR/sslbackup ]; then
   echo "dir $WORKDIR/sslbackup exists."
else
  echo "File $WORKDIR/sslbackup does not exist. creating it"
  mkdir -p $WORKDIR/sslbackup
fi

#Backup of SSL Certs --
LOGFILE=$WORKDIR/sslbackup/backuplog.txt
LOGFILEDATE=$(date +%F_%H-%M-%S)
echo --------------------------- >> $LOGFILE
echo $LOGFILEDATE.tar.gz : >> $LOGFILE 2>&1
tar -czf /$WORKDIR/sslbackup/ssl$LOGFILEDATE.tar.gz /etc/ssl/private >> $LOGFILE 2>&1
tar -tvf /$WORKDIR/sslbackup/ssl$LOGFILEDATE.tar.gz >> $LOGFILE 2>&1 


#check for acme installation

if [ -d $WORKDIR/.acme.sh ]; then
   echo "ACME is in Workdir check if symlink to /root/.acme.sh exists"
   




if [ -L /root/.acme.sh ]; then
   echo "Symlink /root/.acme.sh  exists."
else
  echo "Symlink  to $workdir/.acme.sh does not exist. creating it"
  ln -s $WORKDIR/.acme.sh /root/.acme.sh
fi




else
  echo "ACME is not in Workdir check if in /root/.acme.sh"



if [ -f /root/.acme.sh/acme.sh ]; then
   echo " /root/.acme.sh/acme.sh exists"
   mv /root/.acme.sh $WORKDIR/
 ln -s $WORKDIR/.acme.sh /root/.acme.sh

else
  echo "ACME not installed install it"
  mkdir -p $WORKDIR/sslbackup
  rm -rf /root/.acme.sh
  rm -rf $WORKDIR/.acme.sh  
  curl https://get.acme.sh | sh
  mv /root/.acme.sh $WORKDIR/
  ln -s $WORKDIR/.acme.sh /root/.acme.sh

 fi


fi


export DDNSS_Token=$DDNSS_Token

wget https://github.com/helbgd/acme.sh/raw/master/dnsapi/dns_ddnss.sh -O /data/letsencrypt/.acme.sh/dnsapi/dns_ddnss.sh
wget https://github.com/helbgd/acme.sh/raw/master/deploy/unifick.sh -O /data/letsencrypt/.acme.sh/deploy/unifick.sh
#/root/.acme.sh/acme.sh --install
/root/.acme.sh/acme.sh --install-cronjob 
/root/.acme.sh/acme.sh --issue --dns dns_ddnss --domain $DOMAIN
/root/.acme.sh/acme.sh --deploy --deploy-hook unifick --domain $DOMAIN
