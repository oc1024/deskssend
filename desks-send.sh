#! /bin/sh

cd "$(realpath "$(dirname "$0")")"/DesktopFiles

touch GreatManifest.old
touch GreatManifest

mv -f GreatManifest GreatManifest.old

echo -n > GreatManifest

for icm in ../*/.manifest; do
	echo "Copying icons in" $(realpath "$icm")
	cp -R "$(dirname "$icm")"/hicolor/* -t "$HOME"/.local/share/icons/hicolor
	cat "$icm" >> GreatManifest
done

for i in *.desktop; do
	echo "Adding" "$(realpath "$i")" "to the great manifest"
	echo "$HOME"/local/share/applications/"$i" >> GreatManifest
done

diff GreatManifest.old GreatManifest | grep \< | sed 's/< //g' | while read -r MANIFILE; do
	rm -v "$MANIFILE"
done

desktop-file-install --dir="$HOME"/.local/share/applications *.desktop
