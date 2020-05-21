#!/bin/bash
set -x
#edit this address as needed
LOGIN_ADDRESS=user@myserver.local

#this scrip starts something on <yourServer>
#write the command you want to execute on your server
#if you want to do sudo stuff, setup ssh keys to avoid typing your sudo pass everytime
echo "Do BEEP on myserver.local"
ssh $LOGIN_ADDRESS 'beep'

