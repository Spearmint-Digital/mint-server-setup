#!/bin/bash

#this script assumes you have EC2 command line tools installed

#create a key pair and give it permissions
#ec2-create-keypair $1 | sed 1d > $1.key
#chmod 600 $1.key

ec2-create-keypair $1 | sed 1d > $1.pem
chmod 600 $1.pem

#create the security group if need to
ec2-create-group $1 --description $1
ec2-authorize $1 --protocol tcp --port-range 22
ec2-authorize $1 --protocol tcp --port-range 80

#create and run the instance
EC2_RUN_RESULT=$(ec2-run-instances -instance-type t1.micro --group $1 --key $1 ami-974ddead --user-data-file user-data-script.sh)

INSTANCE_NAME=$(echo ${EC2_RUN_RESULT} | sed 's/RESERVATION.*INSTANCE //' | sed 's/ .*//')

#give the instance a name
ec2addtag $INSTANCE_NAME --tag Name=$1

#get a dedicated IP address
IP_ADDRESS=$(ec2-allocate-address | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')

sleep 30

#associate the IP adress with the isntance
ec2-associate-address --instance $INSTANCE_NAME $IP_ADDRESS

echo Instance $INSTANCE_NAME has been created and assigned static IP Address $IP_ADDRESS

#move the key to ~/.ssh and append details to the config
mv $1.pem ~/.ssh

(echo "Host $1.ec2";
 echo "   User ubuntu";
 echo "   Hostname $IP_ADDRESS";
 echo "   IdentityFile ~/.ssh/$1.pem") >> ~/.ssh/config

#ssh into the instance to see that it worked
#ssh -i $1.key ubuntu@$IP_ADDRESS
ssh $1.ec2

# Since the server signature changes each time, remove the server's entry from ~/.ssh/known_hosts
ssh-keygen -R $IP_ADDRESS

