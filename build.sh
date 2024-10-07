#!/usr/bin/env bash

[ -z "$chat_id" ] && {
    echo "error: chat_id"
    ret=false
}

[ -z "$token" ] && {
    echo "error: token"
    ret=false
}

eval "$ret"

## environment related
WORK_DIR=$(pwd)
IMAGE=$WORK_DIR/out/android12-5.10/dist/Image
sudo ln -sf "/usr/share/zoneinfo/Asia/Makassar" /etc/localtime
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y bc bison build-essential ccache curl flex glibc-source g++-multilib gcc-multilib binutils-aarch64-linux-gnu git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libwxgtk3.0-gtk3-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev python2
mkdir ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
git clone --depth=1 https://github.com/eraselk/Anykernel3 -b gki
echo

## sync manifest
~/bin/repo init -u https://github.com/eraselk/kernel-manifest -b main
~/bin/repo sync -j$(nproc --all)

## kernelsu
[ -n "$USE_KSU" ] && curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s v1.0.1

## build gki
export ARCH=arm64
export DEFCONFIG="gki_defconfig"
LTO=thin BUILD_CONFIG=common/build.config.gki.aarch64 build/build.sh

## zipping
cd $WORK_DIR/common
export kver=$(make kernelversion 2>/dev/null)
[ -z "$kver" ] && export kver="unknown"
cd $WORK_DIR

export date=$(date +"%y%m%d%H%M%S")
[ -n "$USE_KSU" ] && export ZIP_NAME="GKI-$kver-KSU-$date.zip" || export ZIP_NAME="GKI-$kver-$date.zip"

cd $WORK_DIR/Anykernel3
cp $IMAGE .
zip -r9 $ZIP_NAME *
mv $ZIP_NAME $WORK_DIR
cd $WORK_DIR

## upload zip file to telegram
upload_file() {
	local file="$1"
	local msg="$2"

    if [ -f "$file" ]; then
        chmod 777 $file
        curl -s -F document=@$file "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=markdown" \
        -F caption="$msg"
    else
        echo "error: File $file not found"
        exit 1
    fi
}

upload_file "$WORK_DIR/$ZIP_NAME" "*GKI $kver $([-n "$USE_KSU" ] && echo KSU) // $date*"
