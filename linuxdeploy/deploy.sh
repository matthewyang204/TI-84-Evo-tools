#!/usr/bin/env bash
set -euo pipefail

DEPLOYTOOL_DOWNLOAD_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20251107-1/linuxdeploy-x86_64.AppImage"
DEPLOYTOOL_PLUGINQT_DOWNLOAD_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/1-alpha-20250213-1/linuxdeploy-plugin-qt-x86_64.AppImage"

# Check if the installation prefix exists
if [ ! -d target/prefix ]; then
    echo "ERROR: The installation prefix does not exist. Please compile in release mode and stage to target/prefix first."
    exit 1
fi

# Download tools we need
echo "Downloading tools..."
mkdir -p target/tools
if [ ! -f target/tools/linuxdeploy-x86_64.AppImage ]; then
    wget -O target/tools/linuxdeploy-x86_64.AppImage $DEPLOYTOOL_DOWNLOAD_URL
    chmod +x target/tools/linuxdeploy-x86_64.AppImage
fi
if [ ! -f target/tools/linuxdeploy-plugin-qt-x86_64.AppImage ]; then
    wget -O target/tools/linuxdeploy-plugin-qt-x86_64.AppImage $DEPLOYTOOL_PLUGINQT_DOWNLOAD_URL
    chmod +x target/tools/linuxdeploy-plugin-qt-x86_64.AppImage
fi

# Run the deployment tool
echo "Deploying..."
export LD_LIBRARY_PATH="$(${QMAKE:-/usr/bin/qmake} -query QT_INSTALL_LIBS | head -n 1)${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
QMAKE=${QMAKE:-/usr/bin/qmake} QML_SOURCES_PATHS="$PWD/qml" target/tools/linuxdeploy-x86_64.AppImage --plugin qt --executable=target/prefix/bin/ti-evo-tools --appdir=target/prefix
