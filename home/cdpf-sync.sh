#! /bin/bash
#set -x

# when called from cgi, PWD is set to cgi-bin
source "/home/pi/cdpf-env.sh"

cd /home/pi/sync

PID=`ps -Ao pid,command | egrep '[f]eh' | egrep -o '^ *[0-9]+'`
if [ $? -eq 1 ] ; then
	"$CDPF_BASE/cdpf-startup.sh"
	sleep 15s
fi

IP=`ifconfig | egrep -o 'inet addr: *[0-9.]*' | egrep -o '[0-9.]*' | egrep -v '^127[.]'`
echo "IP: $IP"

COUNT=`wget -q -O - "${CDPF_SYNC_URL}?count=1&ip=$IP"`

echo "" >>"$CDPF_LOG"
echo "$DATE Got count of '$COUNT' from: ${CDPF_SYNC_URL}?count=1&ip=$IP " | tee >>"$CDPF_LOG"

echo $COUNT | egrep -qs "[0-9]+"

if [ $? -eq 1 ] ; then
	
	echo "$DATE Network connection unavailable" | tee >>"$CDPF_LOG"
	
else

	rm -f "$CDPF_ALBUM_LIST"

	COUNTS=""

	for i in $(seq 1 $COUNT) ; do
		echo "$DATE Syncing album $i" | tee >>"$CDPF_LOG"
	
		mkdir -p "$CDPF_BASE/sync/$i"
		cd "$CDPF_BASE/sync/$i"

		rm -f filelist.txt
	
		wget -mNrnd -U CDPF -l 1 "${CDPF_SYNC_URL}$i" 2>&1 | tee rawout.txt | egrep '^--' | egrep -io '[-a-zA-Z0-9_.]*[.](jpe?g|png|gif)' | sort -u >filelist.txt
	
		if [ -s filelist.txt ]; then
	
			cat filelist.txt

			NOT_EMPTY=0

			for f in $( shopt -s nocaseglob ; ls *.jpg *.jpeg *.png *.gif 2>/dev/null ) ; do
				grep -qF "$f" filelist.txt
				if [ $? -eq 1 ] ; then
					rm "$f"
				else
					NOT_EMPTY=1
				fi
			done
	
			if [ $NOT_EMPTY -eq 1 ] ; then
				echo "$i" >>"$CDPF_ALBUM_LIST"
			fi
	
			IMAGECOUNT=`ls -1 *.[jgp]* | wc -l`
			STORAGE=`du -sh | awk '{print $1}'`
			
			COUNTS="$COUNTS $IMAGECOUNT"
			
			echo "$DATE Sync: there are $IMAGECOUNT images using $STORAGE of space in album $i" | tee >>"$CDPF_LOG"
	
		else 
			echo "$DATE Sync failed" >>"$CDPF_LOG"
		fi
	
	done

	NUM=$((  ( `cat $CDPF_OFFSET_FILE` + `date "+%j + %H"` ) % `cat $CDPF_ALBUM_LIST | wc -l` + 1 ))

	ALBUM=`sed "${NUM}q;d" $CDPF_ALBUM_LIST`

	echo "$DATE Image counts by album: $COUNTS" | tee >>"$CDPF_LOG"
	echo "$DATE Selected Album: $ALBUM" | tee >>"$CDPF_LOG"

	rm -f "$CDPF_BASE/show" && ln -sf "$CDPF_BASE/sync/$ALBUM" "$CDPF_BASE/show"

fi

kill -SIGURG `cat "$CDPF_PID_FILE"` &>>"$CDPF_LOG"
sleep 1s

PID="`cat \"$CDPF_PID_FILE\"`"

[ -n "$PID" ] && ps --pid $PID >/dev/null || {
	echo "$DATE Restarting $CDPF_FEH_BIN" >>"$CDPF_LOG"
	"$CDPF_BASE/cdpf-startup.sh"
} 

