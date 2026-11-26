#!/usr/bin/env bash
set -euo pipefail

echo "Compiling program..."
cargo install --path . --root target/prefix

echo "Deploying program..."
linuxdeploy/deploy.sh

echo "Patching program..."
linuxdeploy/postdeploy1.sh

printf "Finishing..."
chmod +x target/prefix/ti-evo-tools
echo "done"

echo "Built and staged to target/prefix/ti-evo-tools!"
