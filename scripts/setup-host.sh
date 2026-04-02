#!/bin/bash
# Configure host kernel for Steam user namespace support
# Run once on the VPS host with sudo
set -e

echo "==> Enabling unprivileged user namespaces"

# Enable unprivileged user namespaces
sysctl -w kernel.unprivileged_userns_clone=1 2>/dev/null || true

# Disable Ubuntu's AppArmor restriction on unprivileged user namespaces
sysctl -w kernel.apparmor_restrict_unprivileged_userns=0 2>/dev/null || true

# Persist across reboots
cat > /etc/sysctl.d/99-steam-userns.conf << 'EOF'
kernel.unprivileged_userns_clone=1
kernel.apparmor_restrict_unprivileged_userns=0
EOF

echo "==> Done. Kernel settings applied and persisted."
