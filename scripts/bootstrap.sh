#!/bin/bash
set -euxo pipefail

KERNEL_SERIES="${kernel_version}"
CRIU_REF="${criu_ref}"
ENVIRONMENT="${environment}"

STATUS_DIR="/opt/criu-test"
mkdir -p "$STATUS_DIR"

CURRENT_KERNEL="$(uname -r)"

cat >"$STATUS_DIR/environment" <<EOF
environment=$ENVIRONMENT
requested_kernel=$KERNEL_SERIES
criu_ref=$CRIU_REF
actual_kernel=$CURRENT_KERNEL
EOF

if [[ "$CURRENT_KERNEL" == "$KERNEL_SERIES".* ]]; then
    echo "Running requested kernel: $CURRENT_KERNEL"
    touch "$STATUS_DIR/kernel-ready"

    # Don't rebuild CRIU every time the startup script runs.
    if [[ -f "$STATUS_DIR/criu-ready" ]]; then
        echo "CRIU already provisioned"
        exit 0
    fi

    export DEBIAN_FRONTEND=noninteractive

    apt-get update
    apt-get install -y \
        git \
        build-essential \
        pkg-config \
        protobuf-c-compiler \
        libprotobuf-c-dev \
        libprotobuf-dev \
        protobuf-compiler \
        python3-protobuf \
        libnl-3-dev \
        libnet-dev \
        libcap-dev \
        libaio-dev \
        libnftables-dev

    rm -rf /opt/criu

    git clone https://github.com/checkpoint-restore/criu.git /opt/criu
    cd /opt/criu

    git checkout "$CRIU_REF"

    make -j"$(nproc)"

    ./criu/criu --version > "$STATUS_DIR/criu-version"

    if ./criu/criu check >"$STATUS_DIR/criu-check.log" 2>&1; then
        echo "PASS" > "$STATUS_DIR/result"
    else
        echo "FAIL" > "$STATUS_DIR/result"
    fi

    touch "$STATUS_DIR/criu-ready"
    exit 0
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y "linux-gcp-$KERNEL_SERIES"

# Find exact installed kernel.
INSTALLED_KERNEL="$(
    find /boot -maxdepth 1 -name "vmlinuz-$${KERNEL_SERIES}.*-gcp" \
        -printf '%f\n' |
    sed 's/^vmlinuz-//' |
    sort -V |
    tail -1
)"

if [[ -z "$INSTALLED_KERNEL" ]]; then
    echo "Could not find installed kernel $KERNEL_SERIES"
    exit 1
fi

echo "$INSTALLED_KERNEL" > "$STATUS_DIR/installed-kernel"

sed -i 's/^GRUB_DEFAULT=.*/GRUB_DEFAULT=saved/' /etc/default/grub
update-grub

grub-reboot \
    "Advanced options for Ubuntu>Ubuntu, with Linux $INSTALLED_KERNEL"

echo "Rebooting into $INSTALLED_KERNEL"

reboot