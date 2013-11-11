#! /bin/bash
echo "Location: http://$SERVER_NAME:$SERVER_PORT/"
echo ""

source ~/cdpf-env.sh

OFFSET=`cat $CDPF_OFFSET_FILE`
OFFSET=$(( $OFFSET + 1 ))
echo -n "$OFFSET" >$CDPF_OFFSET_FILE

NUM=$(( ( $OFFSET + `date "+%j + %H"` ) % `cat $CDPF_ALBUM_LIST | wc -l` + 1 ))
ALBUM=`sed "${NUM}q;d" $CDPF_ALBUM_LIST`
rm -f "$CDPF_BASE/show" && ln -sf "$CDPF_BASE/sync/$ALBUM" "$CDPF_BASE/show"

kill -SIGURG `cat "$CDPF_PID_FILE"`
