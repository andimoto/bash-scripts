#!/bin/bash
# Author: andimoto

# This script runs your make target on a remote server. This is useful if you develop something on
# your host and you have no access to the program which is used by the make target. This script
# copies your given directory to the destination path on the remote machine. Then it executes it on the 
# remote machine.
# This is useful when you have just one license for your team, but each team member needs to run this software
# from the make target.
# This script also checks for other users tokens on the remote machine and waits the adjustable timeout to get a free
# slot.
# Please setup ssh keys to access the remote machine if you don't want to type in your ssh pass 100 times while this
# script runs.
# Feel free to modify this as you want!

# NOTE: This is the original script which was written from scratch. No guarantee that everything is working. Over the 
# time I've modified this script (but not on my computer :D) to fit my needs. 

##################################
##	    Settings	       	##
##################################
SERVER=server.local
PORT=22
TOKENDIR=/tmp
TOKEN=buildtoken
TIMEOUT=30
#add further exclude dirs with '--exclude=DIR --exclude=...'
EXCLUDE='--exclude=.git'

##################################
BUILDTARGET=$2


##################################
##	check parameters	##
##################################
if [ -z $1 ]
then
	echo "usage: ./rbuild.sh <DIR_OF_MAKEFILE> <TARGET>"
	exit 0 
fi

##################################
##    set mirror build path	##
##################################
cd $1
BUILDDIR=$PWD
cd -


echo "Starting Remote Build on Server: " $SERVER " Port: " $PORT
echo

##################################
##	is server in use?	##
##################################
ssh $USER@$SERVER -p $PORT 'ls -l '$TOKENDIR/*.$TOKEN' > /dev/null 2> /dev/null'
#checking if TOKEN was found
if [ $? == 0 ]
then
	cnt=0
	RET=0
	echo -e $cnt " s   | Server is used by another User. Waiting for " $TIMEOUT "s...\c"
	TIMEOUT=$((TIMEOUT+1))
	while [ $RET == 0 ]
	do
		ssh $USER@$SERVER -p $PORT 'ls -l '$TOKENDIR/*.$TOKEN' > /dev/null 2> /dev/null' 
		RET=$?
		cnt=$((cnt+1))
		if [ $cnt == $TIMEOUT ]
		then
			echo
			echo "Timeout.. EXIT"
			exit 0
		fi	
		echo -e "\r" $cnt "s\c"
		sleep 1
	done
fi



##################################
##	Check if Build can 	##
##	be started		##
##################################
echo "Server available for build..."
echo
echo "Creating & Syncing Files into " $BUILDDIR
#creating build directory
ssh $USER@$SERVER -p $PORT 'mkdir -p '$BUILDDIR''

#check for mkdir returns
if [ $? == 1 ]
then
	echo "mkdir could not create " $BUILDDIR " on Server " $SERVER
	echo "EXIT"
	exit 0
fi


#checking again for token
ssh $USER@$SERVER -p $PORT 'ls -l '$DESTDIR/*.$TOKEN''
if [ $? == 2 ]
then
	echo "No TOKEN found. Creating temporary TOKEN for this Session..."
	ssh $USER@$SERVER -p $PORT 'touch '$TOKENDIR/$USER.$TOKEN''
else
	echo "Server locked for Build...!  EXIT"
	exit 0
fi


##################################
##	Start Sync		##
##################################
if [ !$? ]
then
	echo "Syncing Files..."
	rsync -e "ssh -p $PORT" --numeric-ids -avz $EXCLUDE $BUILDDIR/ $USER@$SERVER:$BUILDDIR/
fi

##################################
##	BUILD TARGET		##
##################################
if [ !$? ]
then
	echo "Syncing done!..."
	echo
	echo "###################################"
	echo "#       Starting Build...         #"
	echo "###################################"
	echo
	echo "Building selected Target: " $BUILDTARGET
	ssh $USER@$SERVER -p $PORT 'make -C '$BUILDDIR' '$BUILDTARGET''
	echo "###################################"
	echo "#       Build done                #"
	echo "###################################"
fi

##################################
##	Get Artifacts		##
##################################
if [ !$? ]
then
	echo 
	echo "Get Build Result..."
	rsync -e "ssh -p $PORT" -avz $USER@$SERVER:$BUILDDIR/ $BUILDDIR/
fi

##################################
##	Clean up		##
##################################
echo -e "Remove User Token... \c"
ssh $USER@$SERVER -p $PORT 'ls -l '$TOKENDIR/$USER.$TOKEN' > /dev/null 2> /dev/null'
if [ !$? ]
then
	ssh $USER@$SERVER -p $PORT 'rm -Rf '$BUILDDIR''
	ssh $USER@$SERVER -p $PORT 'rm '$TOKENDIR/$USER.$TOKEN''
	if [ $? ]
	then
		echo " done!"
		echo "Temporary Files removed!"
	fi
fi

