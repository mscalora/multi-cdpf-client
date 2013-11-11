#! /bin/bash
echo "Location: http://$SERVER_NAME:$SERVER_PORT/"
echo ""

source ~/cdpf-env.sh

OFFSET=`cat $CDPF_BASE/offset.txt`
OFFSET=$(( $OFFSET + 1 ))
echo -n "$OFFSET" >$CDPF_BASE/offset.txt

NUM=$(( ( $OFFSET + `date "+%j"` ) % `cat $CDPF_ALBUM_LIST | wc -l` + 1 ))
ALBUM=`sed "${NUM}q;d" $CDPF_ALBUM_LIST`
rm -f "$CDPF_BASE/show" && ln -sf "$CDPF_BASE/sync/$ALBUM" "$CDPF_BASE/show"

kill -SIGURG `cat "$CDPF_PID_FILE"`
