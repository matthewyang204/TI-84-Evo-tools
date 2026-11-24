#!/usr/bin/env bash
set -euo pipefail

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
cargo bundle --release
macdeployqt target/release/bundle/osx/ti-evo-tools.app -qmldir=./qml -always-overwrite

mkdir -p $OLDPWD/target/bundle
rm -rf $OLDPWD/target/bundle/ti-evo-tools.app
cp -r target/release/bundle/osx/ti-evo-tools.app $OLDPWD/target/bundle/
cd -
echo "Built and staged to target/bundle/ti-evo-tools.app!"

printf "Cleaning up..."
rm -rf $TEMPDIR
echo "done"

if [[ " $* " == *" --run "* ]]; then
    echo "Running program..."
    target/bundle/ti-evo-tools.app/Contents/MacOS/ti-evo-tools
fi
