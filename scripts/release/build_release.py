#!/usr/bin/env python3
"""Construye distribuciones completas o livianas para el sistema anfitrión."""

from __future__ import annotations

import argparse
import hashlib
import os
import platform
import shutil
import stat
import tarfile
import tempfile
import urllib.request
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PRODUCT = "IDE_CIAA_FPGA"
PACKAGES = {
    "windows": {
        "oss_name": "oss-cad-suite-windows-x64-20261028.tgz",
        "oss_url": "https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-10-28/oss-cad-suite-windows-x64-20261028.tgz",
        "oss_sha": "EB97AF9E5D0B195E570C6A7EE3D29C005BCC60E343D48CB713EF414E4A39E766",
        "ghdl_name": "ghdl-mcode-6.0.0-mingw64.zip",
        "ghdl_url": "https://github.com/ghdl/ghdl/releases/download/v6.0.0/ghdl-mcode-6.0.0-mingw64.zip",
        "ghdl_sha": "C1562B2A4767E34D33159B536B5E36A8A38EBDB6E7672AA9969A4F4AC2CADFFE",
    },
    "linux": {
        "oss_name": "oss-cad-suite-linux-x64-20261028.tgz",
        "oss_url": "https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-10-28/oss-cad-suite-linux-x64-20261028.tgz",
        "oss_sha": "5ED05E6E197CB1C98D079778A560F94EE04F7BC5FA09F2239BF30F032672E7F2",
        "ghdl_name": "ghdl-mcode-6.0.0-ubuntu24.04-x86_64.tar.gz",
        "ghdl_url": "https://github.com/ghdl/ghdl/releases/download/v6.0.0/ghdl-mcode-6.0.0-ubuntu24.04-x86_64.tar.gz",
        "ghdl_sha": "30D6A977B8456D140BBAFECBBE64B1947A3D92EEAE8F5E6D9F528A174F9566E7",
    },
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def obtain(cache: Path, name: str, url: str, expected: str, offline: bool) -> Path:
    destination = cache / name
    if destination.is_file() and sha256(destination) == expected:
        print(f"Paquete verificado: {name}")
        return destination
    if destination.exists():
        destination.unlink()
    if offline:
        raise RuntimeError(f"Falta el paquete verificado requerido: {destination}")
    cache.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(destination.suffix + ".partial")
    print(f"Descargando {url}")
    request = urllib.request.Request(url, headers={"User-Agent": "IDE-CIAA-FPGA-release-builder"})
    with urllib.request.urlopen(request) as response, temporary.open("wb") as output:
        shutil.copyfileobj(response, output)
    actual = sha256(temporary)
    if actual != expected:
        temporary.unlink(missing_ok=True)
        raise RuntimeError(f"SHA-256 incorrecto para {name}: {actual}")
    temporary.replace(destination)
    return destination


def copy_source(destination: Path, variant: str) -> None:
    ignored = shutil.ignore_patterns(
        ".git", "build", "backups", "downloads", "tools", "dist",
        "__pycache__", ".pytest_cache", "*.pyc",
    )
    shutil.copytree(ROOT, destination, ignore=ignored)
    if variant == "complete":
        (destination / "OFFLINE_BUNDLE").write_text(
            "Distribucion autocontenida. Los iniciadores no descargan ni reutilizan herramientas externas.\n",
            encoding="utf-8",
        )
    else:
        (destination / "ONLINE_INSTALLER").write_text(
            "Distribucion liviana. En la primera ejecucion se descargan y verifican las herramientas necesarias.\n",
            encoding="utf-8",
        )


def safe_extract_tar(archive: Path, destination: Path) -> None:
    destination_resolved = destination.resolve()
    with tarfile.open(archive, "r:*") as package:
        for member in package.getmembers():
            target = (destination / member.name).resolve()
            if destination_resolved not in target.parents and target != destination_resolved:
                raise RuntimeError(f"Ruta insegura en {archive.name}: {member.name}")
        try:
            package.extractall(destination, filter="data")
        except TypeError:  # Python anterior a 3.12; los archivos ya fueron verificados por SHA-256.
            package.extractall(destination)


def unpack_tools(system: str, config: dict[str, str], cache: Path, root: Path, offline: bool) -> None:
    tools = root / "tools"
    tools.mkdir()
    oss = obtain(cache, config["oss_name"], config["oss_url"], config["oss_sha"], offline)
    ghdl = obtain(cache, config["ghdl_name"], config["ghdl_url"], config["ghdl_sha"], offline)
    safe_extract_tar(oss, tools)
    ghdl_target = tools / "ghdl-6.0.0"
    if system == "windows":
        with zipfile.ZipFile(ghdl) as package:
            package.extractall(ghdl_target)
        required = [tools / "oss-cad-suite/bin/yosys.exe", ghdl_target / "bin/ghdl.exe"]
    else:
        temporary = tools / ".ghdl-extract"
        safe_extract_tar(ghdl, temporary)
        candidates = [item.parent.parent for item in temporary.glob("**/bin/ghdl")]
        if len(candidates) != 1:
            raise RuntimeError("No se pudo identificar la raiz del paquete GHDL para Linux.")
        shutil.move(str(candidates[0]), ghdl_target)
        shutil.rmtree(temporary, ignore_errors=True)
        required = [tools / "oss-cad-suite/bin/yosys", ghdl_target / "bin/ghdl"]
    missing = [str(item) for item in required if not item.is_file()]
    if missing:
        raise RuntimeError("Herramientas ausentes despues de extraer:\n" + "\n".join(missing))


def normalize_modes(root: Path) -> None:
    for path in root.rglob("*"):
        if path.is_dir():
            path.chmod(0o755)
        elif path.suffix == ".sh" or "/bin/" in path.as_posix() or "/libexec/" in path.as_posix():
            path.chmod(path.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def create_archive(system: str, stage_parent: Path, folder_name: str, output_dir: Path) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    source = stage_parent / folder_name
    if system == "windows":
        archive = output_dir / f"{folder_name}.zip"
        with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6, allowZip64=True) as package:
            for path in source.rglob("*"):
                if path.is_file():
                    package.write(path, Path(folder_name) / path.relative_to(source))
    else:
        normalize_modes(source)
        archive = output_dir / f"{folder_name}.tar.gz"
        with tarfile.open(archive, "w:gz", compresslevel=6) as package:
            package.add(source, arcname=folder_name)
    return archive


def main() -> int:
    host = "windows" if platform.system() == "Windows" else "linux"
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", choices=("windows", "linux"), default=host)
    parser.add_argument("--version", required=True)
    parser.add_argument("--cache", type=Path, default=ROOT / "downloads")
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    parser.add_argument("--variant", choices=("complete", "lite"), default="complete")
    parser.add_argument("--offline", action="store_true", help="no descargar archivos ausentes")
    args = parser.parse_args()
    if args.platform != host:
        raise RuntimeError("Cada paquete debe construirse en su propio sistema operativo para conservar permisos y probar los binarios.")
    version = args.version.removeprefix("v")
    label = "Windows_x64" if args.platform == "windows" else "Linux_x64"
    variant_label = "Completa" if args.variant == "complete" else "Liviana"
    folder_name = f"{PRODUCT}_{version}_{label}_{variant_label}"
    with tempfile.TemporaryDirectory(prefix="ciaa-fpga-release-") as temporary:
        parent = Path(temporary)
        root = parent / folder_name
        copy_source(root, args.variant)
        if args.variant == "complete":
            unpack_tools(args.platform, PACKAGES[args.platform], args.cache.resolve(), root, args.offline)
        archive = create_archive(args.platform, parent, folder_name, args.output.resolve())
    checksum = sha256(archive)
    checksum_file = archive.with_name(archive.name + ".sha256")
    checksum_file.write_text(f"{checksum}  {archive.name}\n", encoding="ascii")
    print(f"Creado: {archive}")
    print(f"SHA-256: {checksum}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
