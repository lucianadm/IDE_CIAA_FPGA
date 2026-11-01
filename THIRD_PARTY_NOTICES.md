# Herramientas de terceros incluidas en las distribuciones

Los paquetes de Windows x64 y Linux x64 incluyen software de terceros sin modificar para que el flujo pueda ejecutarse sin conexión.

## OSS CAD Suite

- Proyecto: <https://github.com/YosysHQ/oss-cad-suite-build>
- Versión del paquete: `2026-10-28`
- Contenido: Yosys, nextpnr, Project IceStorm, Icarus Verilog, Surfer y sus dependencias.
- Licencias: cada distribución conserva el directorio completo `tools/oss-cad-suite/license` provisto por el proyecto. Los componentes no comparten una única licencia.

## GHDL

- Proyecto: <https://github.com/ghdl/ghdl>
- Versión: `6.0.0`, backend mcode.
- Licencia: GNU General Public License, versión 2 o posterior. El texto completo se incluye en `licenses/GPL-2.0.txt`.
- Código fuente correspondiente: <https://github.com/ghdl/ghdl/tree/v6.0.0>.
- Los archivos de las bibliotecas IEEE incluidos por GHDL conservan además sus avisos dentro de `tools/ghdl-6.0.0/lib/ghdl/src`.

La licencia MIT del archivo `LICENSE` cubre solamente el código propio de IDE CIAA FPGA. No reemplaza las licencias anteriores.
