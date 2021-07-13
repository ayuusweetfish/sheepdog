# BOON=~/Downloads/boon-macos-amd64/boon RCEDIT=~/Downloads/rcedit-x64.exe sh assets/build_release.sh

rm -rf release

# Generate icon
SQUARE_ICON="convert res/raw/sheep_1_left.png -background transparent -gravity center -extent 611x611"
${SQUARE_ICON} -scale 256x256 assets/sheep.ico

mkdir assets/sheep.iconset
${SQUARE_ICON} -scale 16x16     assets/sheep.iconset/icon_16x16.png
${SQUARE_ICON} -scale 32x32     assets/sheep.iconset/icon_16x16@2x.png
${SQUARE_ICON} -scale 32x32     assets/sheep.iconset/icon_32x32.png
${SQUARE_ICON} -scale 64x64     assets/sheep.iconset/icon_32x32@2x.png
${SQUARE_ICON} -scale 64x64     assets/sheep.iconset/icon_64x64.png
${SQUARE_ICON} -scale 128x128   assets/sheep.iconset/icon_64x64@2x.png
${SQUARE_ICON} -scale 128x128   assets/sheep.iconset/icon_128x128.png
${SQUARE_ICON} -scale 256x256   assets/sheep.iconset/icon_128x128@2x.png
${SQUARE_ICON} -scale 256x256   assets/sheep.iconset/icon_256x256.png
${SQUARE_ICON} -scale 512x512   assets/sheep.iconset/icon_256x256@2x.png
${SQUARE_ICON} -scale 512x512   assets/sheep.iconset/icon_512x512.png
${SQUARE_ICON} -scale 1024x1024 assets/sheep.iconset/icon_512x512@2x.png
iconutil -c icns assets/sheep.iconset -o assets/sheep.icns

# Generate
${BOON} build . --target all

# Replace icons
# win32
#unzip release/Sheepdog-win32.zip -d release/Sheepdog-win32
#rm release/Sheepdog-win32.zip
#wine ${RCEDIT} release/Sheepdog-win32/sheepdog.exe --set-icon assets/sheep.ico
# win64
#unzip release/Sheepdog-win64.zip -d release/Sheepdog-win64
#rm release/Sheepdog-win64.zip
#wine ${RCEDIT} release/Sheepdog-win64/sheepdog.exe --set-icon assets/sheep.ico
# macos
cp assets/sheep.icns release/Sheepdog.app/Contents/Resources/OS\ X\ AppIcon.icns
cp assets/sheep.icns release/Sheepdog.app/Contents/Resources/GameIcon.icns
rm -rf release/Sheepdog.app/Contents/Resources/_CodeSignature

rm -rf assets/sheep.ico assets/sheep.iconset assets/sheep.icns
