#!/bin/bash

set -e
set -o pipefail

echo "Building human movi index..."
bash /path/to/movi/preprocess_ref.sh default /path/to/assemblies.txt /path/to/out/folder
echo 'Done building'
