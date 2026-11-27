#!/usr/bin/env bash
set -eo pipefail

TEMPDIR=/tmp/build-ti-evo-tools-$(head -c 32 /dev/urandom | shasum -a 256 | awk '{print $1}')
mkdir -p $TEMPDIR
rm -rf $TEMPDIR/* $TEMPDIR/.*
if [ -d target ]; then
    mv target $TEMPDIR/
fi
cp -a . $TEMPDIR
if [ -d $TEMPDIR/target ]; then
    mv $TEMPDIR/target target
fi

cd $TEMPDIR

printf "Checking for cargo-bundle..."
if command -v cargo-bundle >/dev/null 2>&1; then
    echo "found"
else
    echo "not found, installing..."
    cargo install cargo-bundle
fi

if [[ " $* " == *" --deploy-oem204 "* ]]; then
    cp .cargo/config-macos-matthewyang.toml .cargo/config.toml
fi

echo "Compiling program..."
TARGETARG=""
if [[ "$CARGO_BUILD_TARGET" =~ ^(x86_64|aarch64)-apple-darwin$ ]]; then
    TARGET_ARCH="${BASH_REMATCH[1]}"
    [ "$TARGET_ARCH" = "aarch64" ] && TARGET_ARCH="arm64"

    if [ "$(uname -m)" != "$TARGET_ARCH" ]; then
        TARGETARG+=" --target $CARGO_BUILD_TARGET"
        CFLAGS+=" -arch $TARGET_ARCH"
        CXXFLAGS+=" -arch $TARGET_ARCH"
    fi
fi
cargo bundle --release $TARGETARG
macdeployqt "target/release/bundle/osx/TI-84 Toolbox.app" -qmldir=./qml -always-overwrite

mkdir -p $OLDPWD/target/bundle
rm -rf "$OLDPWD/target/bundle/TI-84 Toolbox.app"
cp -r "target/release/bundle/osx/TI-84 Toolbox.app" "$OLDPWD/target/bundle/"
cd -
echo "Built and staged to target/bundle/TI-84 Toolbox.app!"

printf "Cleaning up..."
rm -rf $TEMPDIR
echo "done"

if [[ " $* " == *" --run "* ]]; then
    echo "Running program..."
    'target/bundle/TI-84 Toolbox.app/Contents/MacOS/ti-evo-tools'
fi
