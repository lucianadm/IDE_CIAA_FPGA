#!/usr/bin/env bash
set -euo pipefail
RULE='/etc/udev/rules.d/53-edu-ciaa-ft2232.rules'
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
cat > "$TMP" <<'EOF'
# EDU-CIAA-FPGA: FTDI FT2232H, acceso para herramientas de programacion.
SUBSYSTEM=="usb", ATTR{idVendor}=="0403", ATTR{idProduct}=="6010", MODE="0660", GROUP="plugdev", TAG+="uaccess"
EOF
sudo install -m 0644 "$TMP" "$RULE"
sudo udevadm control --reload-rules
sudo udevadm trigger --attr-match=idVendor=0403 --attr-match=idProduct=6010
echo "Regla instalada: $RULE"
echo 'Cierre y vuelva a abrir la sesion si su distribucion no aplica TAG uaccess inmediatamente.'
