# Formato de `project.json`

## Campos obligatorios

| Campo | Descripción |
|---|---|
| `name` | Nombre usado para la carpeta de salida. |
| `language` | `verilog` o `vhdl`. |
| `top` | Módulo o entidad superior sintetizable. |
| `sources` | Lista de fuentes sintetizables. No incluir el testbench. |
| `pcf` | Archivo de asignación de pines. |

## Resultados de síntesis

```json
"results_dir": "src",
"show_synthesis_report": true
```

- `results_dir` es opcional. Copia allí el informe y el bitstream con fecha y hora, sin sobrescribir ejecuciones anteriores.
- `show_synthesis_report` abre en Windows una ventana con el informe antes de programar la FPGA.
- El asistente interactivo configura automáticamente `results_dir` con la carpeta del archivo que contiene el top level.

## Dispositivo

Para EDU-CIAA-FPGA se utiliza:

```json
"device": {
  "nextpnr_device": "hx8k",
  "package": "tq144:4k",
  "frequency_mhz": 12
}
```

Aunque la FPGA física es HX4K, la base de datos de nextpnr la selecciona como variante `tq144:4k` dentro de `hx8k`.

## Simulación

```json
"simulation": {
  "enabled": true,
  "top": "top_tb",
  "sources": ["sim/top_tb.v"],
  "wave_file": "top.vcd",
  "open_viewer": true
}
```

- `enabled` define el comportamiento predeterminado; el usuario puede cambiarlo desde el menú o la consola.
- `top` es la entidad o módulo del testbench.
- `sources` puede contener varios archivos auxiliares.
- En VHDL, `stop_time` limita la duración y se genera un GHW automáticamente.
- En Verilog, `wave_file` debe coincidir con el nombre usado por `$dumpfile`.

## Varias fuentes e inclusiones

```json
"sources": [
  "src/top.v",
  "src/uart.v",
  "src/control.v"
],
"include_dirs": ["src", "include"]
```

En VHDL, GHDL calcula el orden de análisis mediante importación y elaboración. En Verilog, todas las fuentes se entregan juntas a Icarus Verilog y Yosys.

## Programador

La configuración predeterminada corresponde al canal A del FT2232H integrado:

```json
"programmer": {
  "vid": "0403",
  "pid": "6010",
  "index": 0,
  "interface": "A"
}
```

No cambie estos valores salvo que esté usando otro programador y haya comprobado su identificación.
