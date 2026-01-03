#!/bin/bash

export ZIG_VERSION="0.15.2";

if [ "$TARGETARCH" = "arm64" ]; then
    echo "Building for ARM64 architecture";
    export ZIG_ARCH="aarch64";
else
    echo "Building for x86_64 architecture";
    export ZIG_ARCH="x86_64";
fi
echo "ZIG_ARCH=$ZIG_ARCH";
echo "ZIG_VERSION=$ZIG_VERSION";

mkdir -p "$HOME/sdk/zig${ZIG_VERSION}"

echo "Downloading zig ${ZIG_VERSION} for ${ZIG_ARCH}...";
wget -O zig${ZIG_VERSION}.tar.xz "https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz";
tar -xf zig${ZIG_VERSION}.tar.xz -C $HOME/sdk/zig${ZIG_VERSION} --strip-components=1;
rm zig${ZIG_VERSION}.tar.xz;

echo "zig ${ZIG_VERSION} installed successfully to $HOME/sdk/zig${ZIG_VERSION}!";

