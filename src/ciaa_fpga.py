#!/usr/bin/env python3
"""Flujo reproducible para simular, sintetizar y programar EDU-CIAA-FPGA."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
BUILD_ROOT = ROOT / "build"
TOOLS = ("yosys", "nextpnr-ice40", "icepack", "iceprog", "iverilog", "vvp", "ghdl")


class IdeError(RuntimeError):
    pass


def exe(name: str, required: bool = True) -> str | None:
    path = shutil.which(name)
    if not path and required:
        raise IdeError(f"No se encontró la herramienta '{name}'. Ejecute nuevamente el iniciador del sistema operativo.")
    return path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def project_path(base: Path, value: str) -> Path:
    path = Path(value)
    return path.resolve() if path.is_absolute() else (base / path).resolve()


class Runner:
    def __init__(self, log_file: Path):
        log_file.parent.mkdir(parents=True, exist_ok=True)
        self.log = log_file.open("w", encoding="utf-8", errors="replace")

    def close(self) -> None:
        self.log.close()

    def write(self, text: str) -> None:
        print(text)
        self.log.write(text + "\n")
        self.log.flush()

    def run(self, args: list[str], cwd: Path | None = None, description: str | None = None) -> str:
        if description:
            self.write(f"\n== {description} ==")
        self.write("$ " + subprocess.list2cmdline([str(x) for x in args]))
        process = subprocess.Popen(
            [str(x) for x in args], cwd=str(cwd) if cwd else None,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            text=True, encoding="utf-8", errors="replace",
        )
        assert process.stdout is not None
        captured: list[str] = []
        for line in process.stdout:
            line = line.rstrip("\r\n")
            captured.append(line)
            print(line)
            self.log.write(line + "\n")
        code = process.wait()
        self.log.flush()
        if code != 0:
            raise IdeError(f"{description or args[0]} falló (código {code}).")
        return "\n".join(captured)


def synthesis_report(pnr_output: str, bitstream: Path, requested_mhz: str) -> str:
    labels = {
        "ICESTORM_LC": "Celdas lógicas",
        "ICESTORM_RAM": "Bloques de RAM",
        "SB_IO": "Entradas/salidas",
        "SB_GB": "Buffers globales",
        "ICESTORM_PLL": "PLL",
        "SB_WARMBOOT": "Warmboot",
    }
    utilization: dict[str, tuple[int, int, int]] = {}
    for match in re.finditer(r"(?m)^Info:\s+([A-Z0-9_]+):\s+(\d+)/\s*(\d+)\s+(\d+)%", pnr_output):
        utilization[match.group(1)] = tuple(int(match.group(i)) for i in range(2, 5))

    clocks: dict[str, tuple[float, str, float]] = {}
    frequency_pattern = r"Max frequency for clock '([^']+)':\s+([0-9.]+) MHz \((PASS|FAIL) at ([0-9.]+) MHz\)"
    for match in re.finditer(frequency_pattern, pnr_output):
        clocks[match.group(1)] = (float(match.group(2)), match.group(3), float(match.group(4)))

    lines = [
        "INFORME DE SÍNTESIS, RUTEO Y TEMPORIZACIÓN",
        "=" * 46,
        f"Bitstream: {bitstream.name}",
        f"Tamaño del bitstream: {bitstream.stat().st_size} bytes",
        f"SHA-256: {sha256(bitstream)}",
        "",
        "UTILIZACIÓN DEL FPGA",
    ]
    for key, label in labels.items():
        if key in utilization:
            used, total, percent = utilization[key]
            lines.append(f"{label}: {used} / {total} ({percent}%)")
    if not utilization:
        lines.append("No se pudo extraer la utilización del registro de nextpnr.")

    lines.extend(("", "TEMPORIZACIÓN", f"Frecuencia solicitada: {requested_mhz} MHz"))
    if clocks:
        for clock, (maximum, result, target) in clocks.items():
            status = "CUMPLE" if result == "PASS" else "NO CUMPLE"
            lines.append(f"Reloj {clock}: máxima {maximum:.2f} MHz; objetivo {target:.2f} MHz; {status}")
    else:
        lines.append("No se encontró un reloj con restricción temporal en el diseño.")
    return "\n".join(lines) + "\n"


def load_project(filename: str) -> tuple[dict, Path]:
    path = Path(filename).expanduser().resolve()
    if not path.is_file():
        raise IdeError(f"No existe el proyecto: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
    except (OSError, json.JSONDecodeError) as error:
        raise IdeError(f"No se pudo leer {path}: {error}") from error
    required = ("name", "language", "top", "sources")
    missing = [key for key in required if not data.get(key)]
    if missing:
        raise IdeError("Faltan campos del proyecto: " + ", ".join(missing))
    language = str(data["language"]).lower()
    if language not in ("verilog", "vhdl"):
        raise IdeError("language debe ser 'verilog' o 'vhdl'.")
    data["language"] = language
    return data, path.parent


def resolve_sources(base: Path, values: list[str], label: str) -> list[Path]:
    result = [project_path(base, value) for value in values]
    absent = [str(path) for path in result if not path.is_file()]
    if absent:
        raise IdeError(f"Faltan archivos de {label}:\n  " + "\n  ".join(absent))
    return result


def quote_yosys(path: Path) -> str:
    return '"' + path.as_posix().replace('"', '\\"') + '"'


def simulate_vhdl(runner: Runner, config: dict, base: Path, output: Path) -> Path:
    simulation = config["simulation"]
    sources = resolve_sources(base, config["sources"], "diseño")
    test_sources = resolve_sources(base, simulation["sources"], "testbench")
    tb_top = simulation.get("top")
    if not tb_top:
        raise IdeError("La simulación VHDL necesita simulation.top.")
    stop_time = simulation.get("stop_time", "10ms")
    if not re.fullmatch(r"\d+(?:\.\d+)?(?:fs|ps|ns|us|ms|sec|min|hr)", stop_time):
        raise IdeError(f"Tiempo de simulación inválido: {stop_time}")
    work = output / "ghdl_work"
    work.mkdir()
    all_sources = [str(path) for path in sources + test_sources]
    runner.run([exe("ghdl"), "-i", "--std=08", f"--workdir={work}", *all_sources], description="Importar VHDL")
    runner.run([exe("ghdl"), "-m", "--std=08", f"--workdir={work}", tb_top], description="Elaborar testbench VHDL")
    wave = output / f"{tb_top}.ghw"
    runner.run([
        exe("ghdl"), "-r", "--std=08", f"--workdir={work}", tb_top,
        "--assert-level=error", f"--stop-time={stop_time}", f"--wave={wave}",
    ], description="Simular VHDL")
    return wave


def simulate_verilog(runner: Runner, config: dict, base: Path, output: Path) -> Path | None:
    simulation = config["simulation"]
    sources = resolve_sources(base, config["sources"], "diseño")
    test_sources = resolve_sources(base, simulation["sources"], "testbench")
    tb_top = simulation.get("top")
    if not tb_top:
        raise IdeError("La simulación Verilog necesita simulation.top.")
    image = output / "simulation.vvp"
    include_flags: list[str] = []
    for directory in config.get("include_dirs", []):
        include_flags.extend(("-I", str(project_path(base, directory))))
    runner.run([
        exe("iverilog"), "-g2012", "-s", tb_top, "-o", str(image),
        *include_flags, *[str(path) for path in sources + test_sources],
    ], description="Compilar simulación Verilog")
    runner.run([exe("vvp"), str(image)], cwd=output, description="Simular Verilog")
    wave_name = simulation.get("wave_file")
    if not wave_name:
        return None
    wave = output / wave_name
    if not wave.is_file():
        raise IdeError(f"El testbench no generó la forma de onda esperada: {wave}")
    return wave


def open_wave(runner: Runner, wave: Path, tb_top: str | None) -> None:
    surfer = exe("surfer", required=False)
    gtkwave = exe("gtkwave", required=False)
    if surfer:
        command_file = wave.parent / "mostrar_senales.sucl"
        commands = []
        if tb_top:
            commands.append(f"scope_add_as_group_recursive {tb_top}")
            commands.append("group_unfold_all")
        commands.append("zoom_fit")
        command_file.write_text("\n".join(commands) + "\n", encoding="utf-8")
        runner.write("Cierre Surfer para continuar.")
        runner.run([surfer, "--command-file", str(command_file), str(wave)], description="Abrir diagrama temporal")
    elif gtkwave:
        runner.write("Cierre GTKWave para continuar.")
        runner.run([gtkwave, str(wave)], description="Abrir diagrama temporal")
    else:
        runner.write(f"No hay visor instalado. Forma de onda guardada en: {wave}")


def synthesize(runner: Runner, config: dict, base: Path, output: Path) -> Path:
    sources = resolve_sources(base, config["sources"], "diseño")
    top = config["top"]
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", top):
        raise IdeError(f"Entidad o módulo superior inválido: {top}")
    if config["language"] == "vhdl":
        netlist = output / f"{top}_from_vhdl.v"
        runner.run([
            exe("ghdl"), "--synth", "--std=08", "--out=verilog", f"-o={netlist}",
            *[str(path) for path in sources], "-e", top,
        ], description="Sintetizar VHDL a netlist Verilog")
        read_lines = [f"read_verilog -sv {quote_yosys(netlist)}"]
    else:
        include_options = " ".join(f"-I{quote_yosys(project_path(base, item))}" for item in config.get("include_dirs", []))
        files = " ".join(quote_yosys(path) for path in sources)
        read_lines = [f"read_verilog -sv {include_options} {files}".strip()]

    json_file = output / f"{top}.json"
    ys_file = output / "synthesis.ys"
    ys_file.write_text(
        "\n".join(read_lines + [f"synth_ice40 -top {top} -json {quote_yosys(json_file)}", "check -assert", ""]),
        encoding="ascii",
    )
    runner.run([exe("yosys"), "-Q", "-q", "-s", str(ys_file)], description="Síntesis Yosys")

    if not config.get("pcf"):
        raise IdeError("La síntesis necesita un archivo PCF.")
    pcf = project_path(base, config["pcf"])
    if not pcf.is_file():
        raise IdeError(f"No existe el archivo PCF: {pcf}")
    device = config.get("device", {})
    family = device.get("nextpnr_device", "hx8k")
    package = device.get("package", "tq144:4k")
    frequency = str(device.get("frequency_mhz", 12))
    asc_file = output / f"{top}.asc"
    pnr_output = runner.run([
        exe("nextpnr-ice40"), f"--{family}", "--package", package,
        "--json", str(json_file), "--pcf", str(pcf), "--asc", str(asc_file),
        "--freq", frequency,
    ], description="Asignación de pines, ruteo y temporización")
    bitstream = output / f"{top}.bin"
    runner.run([exe("icepack"), str(asc_file), str(bitstream)], description="Generar bitstream")
    report = synthesis_report(pnr_output, bitstream, frequency)
    report_file = output / "informe_sintesis.txt"
    report_file.write_text(report, encoding="utf-8")
    runner.write("\n== INFORME FINAL ==")
    for line in report.rstrip().splitlines():
        runner.write(line)
    runner.write(f"Informe guardado en: {report_file}")
    return bitstream


def program_flash(runner: Runner, bitstream: Path, programmer: dict | None = None) -> None:
    programmer = programmer or {}
    vid = programmer.get("vid", "0403")
    pid = programmer.get("pid", "6010")
    index = str(programmer.get("index", 0))
    interface = programmer.get("interface", "A")
    explicit_device = f"i:0x{vid}:0x{pid}:{index}"
    generic_device = f"i:0x{vid}:0x{pid}"
    candidates = [
        (generic_device, ["-d", generic_device, "-I", interface]),
        ("selector automatico", ["-I", interface]),
        (explicit_device, ["-d", explicit_device, "-I", interface]),
    ]
    selected_args: list[str] | None = None
    attempted: set[tuple[str, ...]] = set()
    for label, candidate_args in candidates:
        key = tuple(candidate_args)
        if key in attempted:
            continue
        attempted.add(key)
        try:
            runner.run([exe("iceprog"), *candidate_args, "-t"], description=f"Identificar Flash ({label})")
            selected_args = candidate_args
            break
        except IdeError:
            runner.write(f"No se pudo acceder con {label}; se probara el siguiente selector.")
    if selected_args is None:
        if platform.system() == "Windows":
            message = (
                "No se pudo abrir el programador FT2232H de la EDU-CIAA-FPGA. "
                "Abra Zadig, active Options > List All Devices, seleccione solamente "
                "Dual RS232-HS (Interface 0), compruebe USB ID 0403:6010 e interfaz 00, "
                "elija WinUSB y pulse Replace Driver. No cambie Interface 1, porque corresponde "
                "al puerto serie. Despues desconecte y vuelva a conectar la placa, cierre otros "
                "programadores y repita la operacion."
            )
        else:
            message = (
                "No se pudo abrir el programador FT2232H de la EDU-CIAA-FPGA. "
                "Compruebe el cable, cierre otros programadores y ejecute "
                "scripts/linux/install_udev_rules.sh para instalar los permisos USB."
            )
        raise IdeError(message)
    backup_dir = ROOT / "backups"
    backup_dir.mkdir(exist_ok=True)
    backup = backup_dir / f"flash_{datetime.now().strftime('%Y%m%d_%H%M%S')}.bin"
    runner.run([exe("iceprog"), *selected_args, "-R", "512k", str(backup)], description="Respaldar Flash")
    if backup.stat().st_size != 524288:
        raise IdeError("El respaldo de Flash no tiene 524288 bytes. Se canceló la escritura.")
    runner.write(f"Respaldo: {backup} | SHA-256: {sha256(backup)}")
    runner.run([exe("iceprog"), *selected_args, str(bitstream)], description="Programar Flash")
    verify = bitstream.parent / "flash_verification.bin"
    runner.run([exe("iceprog"), *selected_args, "-R", str(bitstream.stat().st_size), str(verify)], description="Leer Flash para comparar")
    if verify.read_bytes() != bitstream.read_bytes():
        raise IdeError("La comparación posterior de la Flash falló.")
    runner.write("PROGRAMACIÓN Y COMPARACIÓN APROBADAS.")


def create_output(name: str) -> Path:
    safe = re.sub(r"[^A-Za-z0-9_.-]+", "_", name)
    output = BUILD_ROOT / safe / datetime.now().strftime("%Y%m%d_%H%M%S")
    output.mkdir(parents=True, exist_ok=False)
    return output


def build_project(project: str, simulate: bool | None, view: bool | None, program: bool) -> Path:
    config, base = load_project(project)
    simulation = config.get("simulation", {})
    do_simulate = bool(simulation.get("enabled", False)) if simulate is None else simulate
    do_view = bool(simulation.get("open_viewer", True)) if view is None else view
    if do_simulate and not simulation.get("sources"):
        raise IdeError("Se pidió simular, pero el proyecto no define simulation.sources.")
    output = create_output(config["name"])
    runner = Runner(output / "execution.log")
    try:
        runner.write(f"Proyecto: {config['name']}")
        runner.write(f"Salida: {output}")
        wave = None
        if do_simulate:
            if config["language"] == "vhdl":
                wave = simulate_vhdl(runner, config, base, output)
            else:
                wave = simulate_verilog(runner, config, base, output)
            runner.write("SIMULACIÓN APROBADA.")
            if wave and do_view:
                open_wave(runner, wave, simulation.get("top"))
        else:
            runner.write("SIMULACIÓN OMITIDA.")
        bitstream = synthesize(runner, config, base, output)
        if program:
            program_flash(runner, bitstream, config.get("programmer"))
        else:
            runner.write("No se programó la placa.")
        return bitstream
    finally:
        runner.close()


def simulate_only(project: str, view: bool) -> Path | None:
    config, base = load_project(project)
    simulation = config.get("simulation", {})
    if not simulation.get("sources"):
        raise IdeError("El proyecto no define testbench.")
    output = create_output(config["name"] + "_simulation")
    runner = Runner(output / "execution.log")
    try:
        wave = simulate_vhdl(runner, config, base, output) if config["language"] == "vhdl" else simulate_verilog(runner, config, base, output)
        runner.write("SIMULACIÓN APROBADA.")
        if wave and view:
            open_wave(runner, wave, simulation.get("top"))
        return wave
    finally:
        runner.close()


def doctor() -> bool:
    print(f"Sistema: {platform.platform()}")
    print(f"Python: {sys.version.split()[0]} ({sys.executable})")
    ok = True
    for name in TOOLS:
        path = exe(name, required=False)
        print(f"{name:16} {'OK  ' + path if path else 'FALTA'}")
        ok &= path is not None
    viewer = exe("surfer", required=False) or exe("gtkwave", required=False)
    print(f"{'visor':16} {'OK  ' + viewer if viewer else 'FALTA (opcional)'}")
    if platform.system() == "Windows":
        print("Driver Windows: MI_00 debe usar WinUSB; MI_01 debe conservar FTDI si se usa UART.")
    else:
        print("Permisos Linux: si iceprog no abre el FT2232H, ejecute scripts/linux/install_udev_rules.sh.")
    return ok


def yes_no(question: str, default: bool) -> bool:
    suffix = "[S/n]" if default else "[s/N]"
    answer = input(f"{question} {suffix}: ").strip().lower()
    if not answer:
        return default
    return answer in ("s", "si", "sí", "y", "yes")


def interactive() -> None:
    examples = sorted((ROOT / "examples").glob("*/project.json"))
    print("\nIDE CIAA FPGA")
    print("1. Diagnóstico")
    print("2. Compilar proyecto")
    print("3. Simular solamente")
    print("4. Programar un bitstream existente")
    option = input("Opción [2]: ").strip() or "2"
    if option == "1":
        if not doctor():
            raise IdeError("Faltan herramientas obligatorias.")
        return
    if option == "4":
        filename = input("Archivo .bin: ").strip().strip('"')
        bitstream = Path(filename).expanduser().resolve()
        if not bitstream.is_file():
            raise IdeError(f"No existe: {bitstream}")
        output = create_output("programacion")
        runner = Runner(output / "execution.log")
        try:
            program_flash(runner, bitstream)
        finally:
            runner.close()
        return
    if examples:
        print("Proyectos incluidos:")
        for index, item in enumerate(examples, 1):
            print(f"  {index}. {item.parent.name}")
        selected = input("Número o ruta de project.json [1]: ").strip() or "1"
        project = str(examples[int(selected) - 1]) if selected.isdigit() and 1 <= int(selected) <= len(examples) else selected.strip('"')
    else:
        project = input("Ruta de project.json: ").strip().strip('"')
    if option == "3":
        simulate_only(project, yes_no("¿Abrir el diagrama temporal?", True))
        return
    do_sim = yes_no("¿Simular antes de sintetizar?", True)
    do_view = yes_no("¿Abrir el diagrama temporal?", True) if do_sim else False
    do_program = yes_no("¿Programar la FPGA después de compilar?", False)
    build_project(project, do_sim, do_view, do_program)


def parser() -> argparse.ArgumentParser:
    result = argparse.ArgumentParser(description="Simulación, síntesis y programación de EDU-CIAA-FPGA")
    commands = result.add_subparsers(dest="command")
    commands.add_parser("doctor", help="verificar herramientas")
    build = commands.add_parser("build", help="simular y sintetizar un proyecto")
    build.add_argument("project")
    sim_group = build.add_mutually_exclusive_group()
    sim_group.add_argument("--simulate", action="store_true", dest="simulate")
    sim_group.add_argument("--no-simulate", action="store_false", dest="simulate")
    build.set_defaults(simulate=None)
    view_group = build.add_mutually_exclusive_group()
    view_group.add_argument("--view", action="store_true", dest="view")
    view_group.add_argument("--no-view", action="store_false", dest="view")
    build.set_defaults(view=None)
    build.add_argument("--program", action="store_true")
    sim = commands.add_parser("simulate", help="ejecutar solo el testbench")
    sim.add_argument("project")
    sim.add_argument("--view", action="store_true")
    prog = commands.add_parser("program", help="programar un .bin existente")
    prog.add_argument("bitstream")
    return result


def main() -> int:
    args = parser().parse_args()
    try:
        if not args.command:
            interactive()
        elif args.command == "doctor":
            return 0 if doctor() else 1
        elif args.command == "build":
            build_project(args.project, args.simulate, args.view, args.program)
        elif args.command == "simulate":
            simulate_only(args.project, args.view)
        elif args.command == "program":
            bitstream = Path(args.bitstream).expanduser().resolve()
            if not bitstream.is_file():
                raise IdeError(f"No existe: {bitstream}")
            output = create_output("programacion")
            runner = Runner(output / "execution.log")
            try:
                program_flash(runner, bitstream)
            finally:
                runner.close()
        return 0
    except (IdeError, OSError, subprocess.SubprocessError, ValueError) as error:
        print(f"\nERROR: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
