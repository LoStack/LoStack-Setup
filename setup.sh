if [[ $(uname -m) =~ ^(aarch64|armv7l|arm64)$ ]]; then
    ./scripts/setup-arm.sh
else
    ./scripts/setup-ubuntu.sh
fi