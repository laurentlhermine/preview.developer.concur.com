#!/bin/bash
#
# Local build script
# Prerequisites:
# Node JS and npm should be installed
# Widdershins must be installed:
#  npm install -g widdershins
#  /usr/local/bin should be in your $PATH
#
set -euo pipefail

# Pre-requisite: install required modules
# Install globally as it's easier for circleci
echo "Installing node dependencies..."
npm install -g node-html-parser
export NODE_PATH=$(npm root --quiet -g)

# Step 1: Clean environment for build
echo "Cleaning build artifact directories..."
set +e
rm -rf src/Slate-API-Explorer-Reference/slate/source/images
rm -rf src/Slate-API-Explorer-Reference/slate/source/includes
rm -rf src/Slate-API-Explorer-Reference/slate/build
rm -rf src/slate-ui/built
mkdir src/Slate-API-Explorer-Reference/slate/source/images
mkdir src/Slate-API-Explorer-Reference/slate/source/includes
mkdir src/Slate-API-Explorer-Reference/slate/build
mkdir src/slate-ui/built
set -e

# Step 2: Remove authentication from swagger files.
echo "Removing authentication from swagger files..."
node ./build-tools/remove_authentication.js

# Step 3: Process swagger files
echo "Processing Swagger JSON files..."
pushd ./src/api-explorer/ && find . -name \*.jsonp -type f -exec bash -c "widdershins {} -o {}.md --omitHeader > /dev/null" \; -print
popd

# Step 4: Correct the indents in the generated markdown
echo "Massaging generated markdown..."
node ./build-tools/adjust_indents.js

# Step 5: Copy generated markdown to slate directory (explorer)
echo "Copying generated markdown (api-explorer)..."
node ./build-tools/explorer_to_slate.js

# Step 6: Copy markdown to slate directory (reference)
echo "Copying markdown (api-reference)..."
node ./build-tools/reference_to_slate.js

# Step 7: Copy basic site files to slate directory
echo "Copying other sources to slate directory..."
node ./build-tools/basicsite_to_slate.js

# Step 8: Cleanup reference files.
echo "Cleanup api-reference markdown..."
node ./build-tools/reference_cleanup.js

# Step 9: Build Slate static files
echo "Generating static html from markdown..."
pushd ./src/Slate-API-Explorer-Reference/slate && bundle install && bundle exec middleman build 2>/dev/null
popd

# Step 10: Move static files to slate-ui directory
echo "Copying static files to slate-ui directory..."
node ./build-tools/slate_to_static.js