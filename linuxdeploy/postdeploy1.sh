#!/usr/bin/env bash
set -euo pipefail

printf "Patching..."
patchelf --set-rpath '$ORIGIN/../lib' target/prefix/bin/ti-evo-tools
cp linuxdeploy/launcher target/prefix/ti-evo-tools
echo "done"
