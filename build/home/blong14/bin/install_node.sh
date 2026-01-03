#!/bin/bash

export NODE_VERSION="24.12.0"

if [ "$TARGETARCH" = "arm64" ]; then
    NODE_ARCH="arm64"
else
    NODE_ARCH="x64"
fi
NODE_DIR="node-v${NODE_VERSION}-linux-${NODE_ARCH}"
NODE_TAR="${NODE_DIR}.tar.xz"

mkdir -p "$HOME/sdk/node${NODE_VERSION}"

echo "Installing Node.js v24.12.0..."
wget "https://nodejs.org/dist/v${NODE_VERSION}/${NODE_TAR}" -O "${NODE_TAR}"
tar -xf "${NODE_TAR}" -C $HOME/sdk/node${NODE_VERSION} --strip-components=1 
rm "${NODE_TAR}"

echo "node ${NODE_VERSION} installed successfully to $HOME/sdk/node${NODE_VERSION}!";
