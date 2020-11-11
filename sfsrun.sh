#! /bin/sh

HERE=$(dirname "$1")

MP="$HERE"/"sfsapp"
mkdir -p "$MP"

squashfuse "$1" "$MP" || exit 1

shift

CMD="$1"

shift

"$MP"/"$CMD" "$@"
wait

cleanup() {
	sleep 1
	fusermount -u "$MP"
}

trap cleanup EXIT INT
