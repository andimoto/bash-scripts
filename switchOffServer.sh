#!/bin/bash

echo "--------Switch off ServerNAS.lan--------"
echo "Connecting and switch off ServerNAS--->"

#connect via ssh and switch of server
#key already generated to connect without password
ssh root@server.local 'shutdown -h now'


if [ $? = 0 ]
then
echo "Server switched off!"
fi

