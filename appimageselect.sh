#! /bin/sh

HERE="$(dirname "$0")"
cd "$HERE"

cd "$1"
	AI=$(ls *.AppImage | sort --version-sort | head -n1) || exit 1
	if [ -n "$AI" ]; then
		chmod +x "$AI"
		ln -sf "$AI" AppImage
		realpath "$AI"
	else
		exit 1
	fi
cd "$HERE"

if [ "$2" = "--run" ]; then
	shift 2
	"$AI" "$@"
	exit $?
fi
