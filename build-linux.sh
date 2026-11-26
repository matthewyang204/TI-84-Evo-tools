#!/usr/bin/env bash
set -euo pipefail

echo "Compiling program..."
cargo install --path . --root target/prefix

echo "Deploying program..."
linuxdeploy/deploy.sh

echo "Patching and packaging program..."
patchelf --set-rpath '$ORIGIN/../lib' target/prefix/bin/ti-evo-tools
cp linuxdeploy/launcher target/prefix/ti-evo-tools
chmod +x target/prefix/ti-evo-tools

echo "Built and staged to target/prefix/ti-evo-tools!"
