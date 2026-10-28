#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TOOLS="$ROOT/tools"
DOWNLOADS="$ROOT/downloads"
mkdir -p "$TOOLS" "$DOWNLOADS"

ARCH="$(uname -m)"
if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
  echo "ERROR: esta version admite Linux x64 sobre procesadores Intel/AMD." >&2
  exit 1
fi

install_base_tools() {
  local missing=()
  command -v curl >/dev/null 2>&1 || missing+=(curl)
  command -v tar >/dev/null 2>&1 || missing+=(tar)
  command -v python3 >/dev/null 2>&1 || missing+=(python3)
  ((${#missing[@]} == 0)) && return
  echo "Faltan herramientas basicas: ${missing[*]}"
  if command -v apt-get >/dev/null 2>&1; then sudo apt-get update && sudo apt-get install -y "${missing[@]}"
  elif command -v dnf >/dev/null 2>&1; then sudo dnf install -y "${missing[@]}"
  elif command -v pacman >/dev/null 2>&1; then sudo pacman -S --needed "${missing[@]}"
  elif command -v zypper >/dev/null 2>&1; then sudo zypper install -y "${missing[@]}"
  else echo 'ERROR: instale curl, tar y python3 con el gestor de paquetes de su distribucion.' >&2; exit 1
  fi
}
install_base_tools

suite_ok() {
  local d="$1"
  [[ -x "$d/bin/yosys" && -x "$d/bin/nextpnr-ice40" && -x "$d/bin/icepack" && -x "$d/bin/iceprog" && -x "$d/bin/iverilog" && -x "$d/bin/vvp" ]]
}
download_checked() {
  local url="$1" dst="$2" expected="$3"
  if [[ -f "$dst" ]] && [[ "$(sha256sum "$dst" | awk '{print toupper($1)}')" == "$expected" ]]; then return; fi
  echo "Descargando $(basename "$dst")..."
  curl -L --fail --retry 3 -o "$dst" "$url"
  local actual
  actual="$(sha256sum "$dst" | awk '{print toupper($1)}')"
  [[ "$actual" == "$expected" ]] || { echo "ERROR: SHA-256 incorrecto para $dst" >&2; exit 1; }
}

SUITE="$TOOLS/oss-cad-suite"
if ! suite_ok "$SUITE"; then
  if command -v yosys >/dev/null 2>&1 && command -v nextpnr-ice40 >/dev/null 2>&1 && command -v icepack >/dev/null 2>&1 && command -v iceprog >/dev/null 2>&1 && command -v iverilog >/dev/null 2>&1 && command -v vvp >/dev/null 2>&1; then
    SUITE=""
    echo 'Se reutilizaran las herramientas instaladas en el sistema.'
  else
    VERSION='2026-10-28'
    NAME='oss-cad-suite-linux-x64-20261028.tgz'
    ARCHIVE="$DOWNLOADS/$NAME"
    download_checked "https://github.com/YosysHQ/oss-cad-suite-build/releases/download/$VERSION/$NAME" "$ARCHIVE" '5ED05E6E197CB1C98D079778A560F94EE04F7BC5FA09F2239BF30F032672E7F2'
    STAGE="$TOOLS/extract_oss_$$"
    mkdir -p "$STAGE"
    echo 'Extrayendo OSS CAD Suite...'
    tar -xzf "$ARCHIVE" -C "$STAGE"
    FOUND="$(find "$STAGE" -type d -name oss-cad-suite -print -quit)"
    [[ -n "$FOUND" ]] && suite_ok "$FOUND" || { echo 'ERROR: paquete OSS CAD Suite invalido.' >&2; exit 1; }
    [[ -e "$SUITE" ]] && mv "$SUITE" "$SUITE.anterior_$(date +%Y%m%d_%H%M%S)"
    mv "$FOUND" "$SUITE"
  fi
fi

if [[ -n "$SUITE" ]]; then
  export PATH="$SUITE/bin:$PATH"
  export LD_LIBRARY_PATH="$SUITE/lib:${LD_LIBRARY_PATH:-}"
  export CIAA_TOOLCHAIN="$SUITE"
fi

if ! command -v ghdl >/dev/null 2>&1; then
  GHDL_DIR="$TOOLS/ghdl-6.0.0"
  if [[ ! -x "$GHDL_DIR/bin/ghdl" ]]; then
    NAME='ghdl-mcode-6.0.0-ubuntu24.04-x86_64.tar.gz'
    ARCHIVE="$DOWNLOADS/$NAME"
    download_checked "https://github.com/ghdl/ghdl/releases/download/v6.0.0/$NAME" "$ARCHIVE" '30D6A977B8456D140BBAFECBBE64B1947A3D92EEAE8F5E6D9F528A174F9566E7'
    STAGE="$TOOLS/extract_ghdl_$$"
    mkdir -p "$STAGE"
    tar -xzf "$ARCHIVE" -C "$STAGE"
    FOUND="$(find "$STAGE" -type f -path '*/bin/ghdl' -print -quit)"
    [[ -n "$FOUND" ]] || { echo 'ERROR: paquete GHDL invalido.' >&2; exit 1; }
    FOUND="$(dirname "$(dirname "$FOUND")")"
    [[ -e "$GHDL_DIR" ]] && mv "$GHDL_DIR" "$GHDL_DIR.anterior_$(date +%Y%m%d_%H%M%S)"
    mv "$FOUND" "$GHDL_DIR"
  fi
  export PATH="$GHDL_DIR/bin:$PATH"
  export LD_LIBRARY_PATH="$GHDL_DIR/lib:${LD_LIBRARY_PATH:-}"
fi

echo "Herramientas listas${SUITE:+: $SUITE}"
exec python3 "$ROOT/src/ciaa_fpga.py" "$@"
