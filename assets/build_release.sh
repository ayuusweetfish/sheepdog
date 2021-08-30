# BOON=~/Downloads/boon-macos-amd64/boon RCEDIT=~/Downloads/rcedit-x64.exe LOVE_ANDROID=../love-android ANDROID_HOME=~/Library/Android/sdk JAVA_HOME=/usr/local/Cellar/openjdk/15.0.2 sh assets/build_release.sh

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
unzip release/Sheepdog-win32.zip -d release/Sheepdog-win32
rm release/Sheepdog-win32.zip
wine ${RCEDIT} release/Sheepdog-win32/sheepdog.exe --set-icon assets/sheep.ico
# win64
unzip release/Sheepdog-win64.zip -d release/Sheepdog-win64
rm release/Sheepdog-win64.zip
wine ${RCEDIT} release/Sheepdog-win64/sheepdog.exe --set-icon assets/sheep.ico
# macos
cp assets/sheep.icns release/Sheepdog.app/Contents/Resources/OS\ X\ AppIcon.icns
rm -rf release/Sheepdog.app/Contents/Resources/_CodeSignature
rm release/Sheepdog.app/Contents/Resources/Assets.car
rm release/Sheepdog.app/Contents/Resources/GameIcon.icns
perl -0777 -pi -e 's/\s<key>CFBundleIconName<\/key>\n\s+<string>OS X AppIcon<\/string>\n//g' release/Sheepdog.app/Contents/Info.plist

zip release/Sheepdog-win32.zip -r release/Sheepdog-win32 -9
zip release/Sheepdog-win64.zip -r release/Sheepdog-win64 -9
zip release/Sheepdog.app.zip -r release/Sheepdog.app -9

rm -rf assets/sheep.ico assets/sheep.iconset assets/sheep.icns

# Android
${SQUARE_ICON} -scale 42x42   ${LOVE_ANDROID}/app/src/main/res/drawable-mdpi/love.png
${SQUARE_ICON} -scale 72x72   ${LOVE_ANDROID}/app/src/main/res/drawable-hdpi/love.png
${SQUARE_ICON} -scale 96x96   ${LOVE_ANDROID}/app/src/main/res/drawable-xhdpi/love.png
${SQUARE_ICON} -scale 144x144 ${LOVE_ANDROID}/app/src/main/res/drawable-xxhdpi/love.png
${SQUARE_ICON} -scale 192x192 ${LOVE_ANDROID}/app/src/main/res/drawable-xxxhdpi/love.png
cp release/Sheepdog.love ${LOVE_ANDROID}/app/src/main/assets/game.love
# Unsigned APK
# cd ${LOVE_ANDROID} && ./gradlew assembleEmbedRelease
# cp ${LOVE_ANDROID}/app/build/outputs/apk/embed/release/app-embed-release-unsigned.apk release/Sheepdog.apk
(cd ${LOVE_ANDROID} && ./gradlew bundleEmbedRelease)
bundletool build-apks --bundle=${LOVE_ANDROID}/app/build/outputs/bundle/embedRelease/app-embed-release.aab --output=release/Sheepdog.apks --mode=universal
unzip release/Sheepdog.apks universal.apk -d release
mv release/universal.apk release/Sheepdog.apk
rm release/Sheepdog.apks

# Emscripten
love.js --title Sheepdog release/Sheepdog.love release/Sheepdog-web
cp assets/Caddyfile release/Sheepdog-web
zip release/Sheepdog-web.zip -r release/Sheepdog-web
