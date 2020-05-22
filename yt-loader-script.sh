#!/bin/bash

#change path
DOWNLOAD_PATH_MUSIC=/home/$USER/Musik
DOWNLOAD_PATH_VIDEO=/home/$USER/Videos

# ----- application variables -----
# zenity: easy gtk window creator for getting user interactions
# xclip: get content from CLIPBOARD
# YTDL_PKG_MGR: edit which package manager should be user to install/upgrade youtube_dl
# YTDL: youtube-dl command
# app path: standard path for zenity & xclip
ZENITY_APP=zenity
XCLIP_APP=xclip
YTDL_PKG_MGR=pip
YTDL=youtube-dl
APP_PATH=/usr/bin

# depending on /etc/lsb_release choose which command should provide root privileges
# Ubuntu 18.04 based derivates should use pkexec from policykit-1
# previous derivates should or can use gksudo from gksu
SU_EXEC_GKSU=gksudo
SU_EXEC_PKEXEC=pkexec
# set EXEC variable, leave as comment if no special priviledges are required
SU_EXEC=$SU_EXEC_PKEXEC




ZENITY_EXISTS=0

if [ -x $APP_PATH/$ZENITY_APP ]
then echo "zenity found!"
	ZENITY_EXISTS=1
else
	echo "zenity ist nicht installiert. Versuche zenity zu installieren! Bitte Passwort eingeben."
	$SU_EXEC apt install $ZENITY_APP
	if [ $? = 0 ]
	then #successfully installed
		ZENITY_EXISTS=1
	fi
fi
#check for xclip
if [ -x $APP_PATH/$XCLIP_APP ]
then
	echo "xclip found!"
else
	$APP_PATH/$ZENITY_APP --info --width=300 \
				--text "xclip nicht gefunden. Versuche xclip zu installieren! \nBitte das Passwort im nächsten Fenster eingeben." 2> /dev/null

	$SU_EXEC apt install $XCLIP_APP
	if [ $? = 0 ]
	then #successfully installed
		echo "xclip installed"
	else
		echo "xclip fehlt | xclip not found"
		read -p "Press enter to exit"
		exit 0
	fi
fi


# set arguments
if [ $1 = "--video" ]
then
	YTDL_ARGS='-f mp4'
	DOWNLOAD_PATH=$DOWNLOAD_PATH_VIDEO
elif [ $1 = "--music" ]
then
	YTDL_ARGS='-x --audio-format mp3'
	DOWNLOAD_PATH=$DOWNLOAD_PATH_MUSIC
else
	$APP_PATH/$ZENITY_APP --info --width=300 \
		--text "Bitte Download-Typ angeben:\n--video oder --music\n
			(yt-loader-script.sh --video " 2> /dev/null
fi

# go into destination directory and start downloading from youtube
cd $DOWNLOAD_PATH
pwd
CLIPBOARD=`xclip -out`
echo "hole '$CLIPBOARD' von youtube..."

# run command
youtube-dl --no-playlist -o "%(title)s.%(ext)s" $YTDL_ARGS $CLIPBOARD


if [ $? = 0 ]
then
	echo "FERTIG! | READY!"

	$APP_PATH/$ZENITY_APP --info --width=300 \
		--text "Titel erfolgreich von Youtube nach \n'$DOWNLOAD_PATH' geladen!" 2> /dev/null

else
# youtube-dl was not successful. either the link is missing or wrong
# or youtube_dl needs to be upgraded or installed
	$APP_PATH/$ZENITY_APP --question --width=300 \
		--text "Youtube-dl muss aktualisiert werden oder ist nicht installiert.
			\nKlicke 'Ja' um Youtube-dl zu installieren \n(Python Paket: pip).
			\n\nWenn 'Ja' - Achtung: Im nächsten Fenster muss das Passwort angegeben werden." 2> /dev/null
	if [ $? = 0 ]
	then
			$SU_EXEC pip install $YTDL
	else
		$APP_PATH/$ZENITY_APP --error --width=300 \
			--text "FEHLER! Titel kann nicht geladen werden" 2> /dev/null
		exit 0
	fi

	if [ $? = 0 ]
	then
		$APP_PATH/$ZENITY_APP --info --width=300 \
			--text "Bitte Youtube Link wieder kopieren und neu starten!" 2> /dev/null
	fi
fi
