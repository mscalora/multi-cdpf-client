#! /bin/bash
#set -x

# when called from cgi, PWD is set to cgi-bin
source "/home/pi/cdpf-env.sh"

cd /home/pi/sync

count=`wget -q -O - "${CDPF_SYNC_URL}?count"`

echo "Getting count from: ${CDPF_SYNC_URL}?count"
echo "Got: $count"

echo $count | egrep "[0-9]+"

if [ $? -eq 1 ] ; then
	exit
fi

echo "Getting photos"

CDPF_ALBUM_LIST="$CDPF_BASE/albumlist.txt"

rm -f "$CDPF_ALBUM_LIST"

for i in $(seq 1 $count) ; do
	echo "Syncing album $i"
	
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
	
		echo "$DATE Sync: there are `cat filelist.txt | wc -l` files, `du -ch *.[jpg]* | tail -n 1 | egrep -o \"^\\S*\"` total - $CDPF_SYNC_URL" >>"$CDPF_LOG"
	
	else 
		echo "$DATE Sync failed" >>"$CDPF_LOG"
	fi
	
done

NUM=$(( `date "+%j"` % `cat $CDPF_ALBUM_LIST | wc -l` + 1 ))

echo "Album Nth line: $NUM"

ALBUM=`sed "${NUM}q;d" $CDPF_ALBUM_LIST`

echo "Selected $ALBUM"

rm -f "$CDPF_BASE/show" && ln -sf "$CDPF_BASE/sync/$ALBUM" "$CDPF_BASE/show"

kill -SIGURG `cat "$CDPF_PID_FILE"` &>>"$CDPF_LOG"
sleep 1s

PID="`cat \"$CDPF_PID_FILE\"`"

[ -n "$PID" ] && ps --pid $PID >/dev/null || {
	echo "$DATE Restarting $CDPF_FEH_BIN" >>"$CDPF_LOG"
	"$CDPF_BASE/cdpf-startup.sh"
} 

