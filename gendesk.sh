#! /bin/bash

cd "$(dirname "$0")"


find_icons() {
	ICO_SUCCESS=1
	for i in hicolor/*/apps/"$ICONAME".*; do
		ICO_SUCCESS=0
		(
			cd "$(dirname "$i")"
			FILENAME=$(basename "$i")
			mv "$FILENAME" _apps_folder_script_"$FILENAME" || exit 1
		) || { ICO_SUCCESS=1; break; }
	done
	
	if [ $ICO_SUCCESS -eq 0 ]; then 
		while read -r ICOMAN; do
			echo "$HOME"/.local/share/icons/"$ICOMAN" >> .manifest
		done < <(find hicolor -type f)
	fi
	
	echo "Icon=_apps_folder_script_${ICONAME}"
	
	return $ICO_SUCCESS
}

rm -rf DesktopFiles/*.desktop

shopt -s nullglob # Do not expand *.* if no results are available.

# Assemble desktop from "prodesktop" files

for pd in */*.prodesktop; do
	OUT=$(basename "$pd")
	OUT=${OUT%.prodesktop}
	DIR=$(realpath "$(dirname "$pd")")
	# Just replace some relative paths here and there.
	sed -e "s|=../|=${PWD}/|g" \
	    -e "s|=./|=${DIR}/|g" \
	"$pd" > "$OUT".desktop
	
	(
		cd "$DIR"
		
		[ -d icons ] || exit
		echo -n > .manifest
		ICONAME=$(find icons/* -type f | head -n1)
		ICONAME=${ICONAME##*/}
		ICONAME=${ICONAME%.*}
		touch hicolor
		rm -rf hicolor
		cp -R icons hicolor
		echo $ICONAME
		ICON_E=$(find_icons) && sed -i "s|^Icon=.*|${ICON_E}|g" ../"$OUT".desktop
		echo $ICON_E
	)
done

# Assemble desktop from AppImages
HERE=$PWD
for DIR in */; do
	cd "$HERE"
	./appimageselect.sh "$DIR" || continue
	
	cd "$DIR"
	mkdir -p squashfs-root
	touch hicolor
	rm -rf hicolor
	AI_OFFSET=$(./AppImage --appimage-offset) || continue
	squashfuse AppImage -o offset="$AI_OFFSET" squashfs-root
	
	pushd squashfs-root
		cp -R usr/share/icons/hicolor/ ..
		DESKFILE=$(ls *.desktop | head -n1)
		ICONAME=$(sed -n '/^Icon=/p' "$DESKFILE" | cut -d= -f2)
		ICON=$(ls "$ICONAME".* | grep -v .desktop$ | head -n1)
		cp "$DESKFILE" "$ICON" ..
	popd
	
	fusermount -u squashfs-root
	
	echo -n > .manifest
	
	ICON_E="Icon=$(realpath "$ICON")"
	TMP=$(find_icons) && ICON_E=$TMP
	
	echo Icon Sed: "$ICON_E"
	sed -i \
	   -e "s|Exec=[[:graph:]]\+|Exec=${PWD}/AppImage|g" \
	   -e "s|^Icon=.*|${ICON_E}|g" \
	   -e "/^X-AppImage-Version=/d" \
	"$DESKFILE"
	
	mv "$DESKFILE" ..
done

shopt -u nullglob

mv *.desktop DesktopFiles
