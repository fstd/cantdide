#!/bin/sh
chan='#mychan'
nick='mynick'
srv='irc.example.org'
trigs='triggers.txt'
tc=','

fifo="$(mktemp /tmp/cbot.fifo.XXXXXXXXXXX)"; rm "$fifo"; mkfifo "$fifo"

trap "rm -f '$fifo'" EXIT
trap 'exit 1' INT HUP QUIT TERM

( while [ -e "$fifo" ]; do sleep 60; done >"$fifo" ) &

#icat from https://github.com/fstd/libsrsirc
icat -vvvcktrE/ -n "$nick" -C "$chan" "$srv" <"$fifo" | while read -r who ident where what rest; do
	printf '%s\n' "$what" | grep -E "^$tc[a-zA-Z0-9_:,-]+$" || continue
	printf '%s\n' "$rest" | grep -E '^[][a-zA-Z0-9\`_^{|}-]+$' && who="$rest"

	resp="$(grep -i -- "^$where ${what#$tc} " "$trigs" | cut -d ' ' -f 3- | head -n1)"
	[ -n "$resp" ] && echo "$where $who: $resp" >>"$fifo";
done
