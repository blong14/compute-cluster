#!/bin/bash

# Set Go version
export GO_VERSION="1.24.2"

if [ "$TARGETARCH" = "arm64" ]; then
    echo "Building for ARM64 architecture";
    export GO_ARCH="arm64";
else
    echo "Building for x86_64 architecture";
    export GO_ARCH="amd64";
fi
echo "GO_ARCH=$GO_ARCH"
echo "GO_VERSION=$GO_VERSION"

# Create Go directory in home directory if it doesn't exist
mkdir -p "$HOME/go"
mkdir -p "$HOME/go/bin"
mkdir -p "$HOME/go/pkg"
mkdir -p "$HOME/go/src"

# Download Go
echo "Downloading Go ${GO_VERSION} for ${GO_ARCH}..."
curl -sSL https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz | tar -C "$HOME/sdk" -xz 

echo "Go ${GO_VERSION} installed successfully to $HOME/go!"
echo "Please run 'source ~/.bashrc' or start a new terminal to use Go"

