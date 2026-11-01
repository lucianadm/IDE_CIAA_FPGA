# IDE CIAA FPGA

Entorno reproducible para trabajar con la **EDU-CIAA-FPGA** desde Windows o Linux. Permite:

## Descargar el programa

### [Descargar IDE CIAA FPGA 1.0.0 para Windows x64](https://github.com/lucianadm/IDE_CIAA_FPGA/releases/download/v1.0.0/IDE_CIAA_FPGA_1.0.0_Windows_x64.zip)

Para instalar y usar el programa, descargá el paquete anterior o ingresá a la sección [Releases](https://github.com/lucianadm/IDE_CIAA_FPGA/releases). **No uses `Code > Download ZIP` para instalarlo:** esa opción de GitHub contiene solamente el código fuente y no incluye los compiladores ni las herramientas de programación.

Este entorno se basa en la placa, la documentación y los recursos abiertos del proyecto [EDU-CIAA-FPGA de Proyecto CIAA](https://www.proyecto-ciaa.com.ar/devwiki/doku.php%3Fid=desarrollo:edu-fpga.html). La placa fue desarrollada por el Grupo de Investigación y Desarrollo de Sistemas Embebidos (ASE) de la Universidad Tecnológica Nacional, Facultad Regional Haedo.

- simular diseños Verilog/SystemVerilog con Icarus Verilog;
- simular VHDL 2008 con GHDL;
- abrir diagramas temporales con Surfer o GTKWave;
- sintetizar con Yosys;
- asignar pines y rutear con nextpnr-ice40;
- generar bitstreams con IceStorm;
- mostrar y guardar un informe de utilización y frecuencia máxima;
- identificar, respaldar, programar y comparar la Flash con `iceprog`.

El código fuente y las distribuciones listas para usar están separados:

- [Releases](https://github.com/lucianadm/IDE_CIAA_FPGA/releases): paquetes autocontenidos para usar sin Internet, con herramientas y licencias completas.
- **Code > Download ZIP**: código fuente para desarrollo; no sirve como instalador y no contiene compiladores ni programadores.

Los paquetes de Releases usan exclusivamente las herramientas incluidas en `tools`. No descargan componentes, no necesitan Git LFS y no requieren permisos de administrador para simular, sintetizar o generar un bitstream.

## Sistemas admitidos

- Windows 10 u 11 x64, procesador Intel o AMD.
- Linux x64, procesador Intel o AMD. La distribución se prueba en Ubuntu 24.04; otras distribuciones necesitan una versión de glibc compatible.

El destino configurado es la EDU-CIAA-FPGA con **Lattice iCE40HX4K-TQ144** y reloj de 12 MHz. nextpnr representa esta variante mediante `--hx8k --package tq144:4k`.

## Recursos de la FPGA

La capacidad oficial del dispositivo `iCE40HX4K-TQ144` es:

| Recurso | Cantidad |
|---|---:|
| Celdas lógicas LUT4 + flip-flop | 3.520 |
| Bloques de RAM `RAM4K` | 20 |
| RAM embebida total | 80 Kbit (10 KiB) |
| PLL | 2 |
| Redes globales de reloj | 8 |
| Bloques DSP o multiplicadores dedicados | 0 |

Cada bloque `RAM4K` almacena 4.096 bits y admite distintas organizaciones de ancho y profundidad. Yosys puede inferirlos a partir de una memoria sincrónica escrita de manera compatible. Los PLL se utilizan mediante primitivas como `SB_PLL40_CORE` o `SB_PLL40_PAD`; no se infieren a partir de un divisor común. Como no hay bloques DSP, las multiplicaciones se implementan con lógica y registros.

La base abierta utilizada por nextpnr identifica este encapsulado mediante `hx8k/tq144:4k` y puede informar 7.680 celdas y 32 bloques RAM. Esas cifras corresponden a la representación de la herramienta. Para dimensionar un diseño conforme a la especificación del componente se deben usar los límites oficiales del HX4K: 3.520 celdas, 20 RAM y 2 PLL. Fuente: [iCE40 LP/HX Family Data Sheet de Lattice](https://www.latticesemi.com/-/media/LatticeSemi/Documents/DataSheets/iCE/FPGA-DS-02029-4-3-iCE40-LP-HX-Family-Data-Sheet.ashx?document_id=49312).

## Inicio rápido en Windows

1. Descargar `IDE_CIAA_FPGA_<version>_Windows_x64.zip` desde Releases y comprobar su SHA-256 con `SHA256SUMS.txt`.
2. Extraer todo el ZIP. No requiere una ubicación fija.
3. Ejecutar `IDE_CIAA_FPGA.bat`.
4. Leer el cartel inicial y elegir VHDL o Verilog/SystemVerilog.
5. Seleccionar juntos todos los archivos sintetizables del diseño e indicar inmediatamente el top level.
6. Responder si se quiere ejecutar la simulación funcional RTL. El testbench se solicita solamente cuando la respuesta es afirmativa.
7. Revisar el diagrama temporal, que se abre automáticamente si la simulación termina correctamente.
8. Seleccionar el archivo PCF, sintetizar, rutear y generar el bitstream. Para llegar hasta este punto no es necesario conectar la placa.
9. Revisar el informe de síntesis y elegir `Programar FPGA` o `No programar`. Solo la primera opción intenta acceder al dispositivo.

El selector admite varios archivos tanto para el diseño como para el testbench. La primera simulación es funcional RTL y no necesita el PCF. Después de una simulación correcta abre automáticamente el diagrama temporal. En VHDL también pregunta la duración máxima. En Verilog agrega un envoltorio de simulación que genera el archivo VCD aunque el testbench no incluya `$dumpfile` y `$dumpvars`. Se conservan los comandos de consola para automatizar el flujo mediante un `project.json`.

El diagrama temporal de la simulación RTL no contiene los retardos físicos del FPGA. Durante el ruteo, nextpnr realiza análisis temporal estático y comprueba si el diseño cumple la frecuencia indicada en `frequency_mhz`. Este flujo no genera una simulación post-ruteo con retardos anotados.

Al finalizar la síntesis se muestra un resumen con celdas lógicas, bloques de RAM, entradas/salidas, buffers globales, PLL, tamaño del bitstream y frecuencia máxima de cada reloj. En el asistente de Windows aparece una ventana con el informe completo y los botones `Programar FPGA` y `No programar`. El informe y el `.bin` se copian con fecha y hora junto al archivo que contiene el top level; también permanecen en la carpeta interna `build`.

La distribución detecta el archivo `OFFLINE_BUNDLE` y se detiene con un error claro si faltan herramientas. En ese modo nunca descarga paquetes ni reutiliza una instalación externa de Apio.

Para usar la placa, **FT2232H Interface A / MI_00** debe tener WinUSB. **Interface B / MI_01** debe conservar el controlador FTDI si se utilizará como puerto UART. El entorno nunca cambia controladores automáticamente.

## Inicio rápido en Linux

Descargar `IDE_CIAA_FPGA_<version>_Linux_x64.tar.gz`, comprobar su SHA-256 y extraerlo. Dar permiso de ejecución una sola vez si el sistema de archivos no conservó los permisos:

```bash
chmod +x IDE_CIAA_FPGA.sh scripts/linux/*.sh
```

Luego ejecutar:

```bash
./IDE_CIAA_FPGA.sh
```

Si `iceprog` no tiene permiso para acceder al FT2232H:

```bash
./scripts/linux/install_udev_rules.sh
```

Ese script instala una regla limitada a `VID_0403/PID_6010`. Puede pedir la contraseña de administrador.

## Uso por consola

Windows:

```bat
IDE_CIAA_FPGA.bat doctor
IDE_CIAA_FPGA.bat build examples\leds_vhdl\project.json --simulate --view
IDE_CIAA_FPGA.bat build examples\leds_verilog\project.json --no-simulate
IDE_CIAA_FPGA.bat build examples\leds_vhdl\project.json --simulate --no-view --program
IDE_CIAA_FPGA.bat simulate examples\leds_vhdl\project.json --view
IDE_CIAA_FPGA.bat program build\mi_proyecto\FECHA\top.bin
```

Linux usa los mismos argumentos:

```bash
./IDE_CIAA_FPGA.sh doctor
./IDE_CIAA_FPGA.sh build examples/leds_vhdl/project.json --simulate --view
```

## Crear un proyecto

Copiar `templates/project.json` junto con estas carpetas:

```text
mi_proyecto/
├── project.json
├── src/       fuentes sintetizables
├── sim/       testbench y auxiliares de simulación
└── pins/      asignación PCF
```

Los archivos se resuelven respecto de la ubicación de `project.json`, por lo que el proyecto puede estar fuera de esta carpeta. Se admiten varias fuentes en `sources` y `simulation.sources`.

El formato completo está explicado en [docs/FORMATO_PROYECTO.md](docs/FORMATO_PROYECTO.md).

## Seguridad durante la programación

Antes de escribir la Flash, el programa:

1. ejecuta `iceprog -t`;
2. lee los 512 KiB y guarda un respaldo en `backups`;
3. comprueba el tamaño del respaldo;
4. escribe el bitstream;
5. vuelve a leer la cantidad de bytes escrita;
6. compara ambos archivos byte por byte.

La opción `--program` reemplaza el diseño existente en la Flash. Sin esa opción solo se genera el bitstream.

## Estructura del repositorio

```text
IDE_CIAA_FPGA/
├── IDE_CIAA_FPGA.bat             inicio para Windows
├── IDE_CIAA_FPGA.sh              inicio para Linux
├── src/ciaa_fpga.py              flujo común
├── scripts/windows/              instalación Windows
├── scripts/linux/                instalación y permisos Linux
├── scripts/release/              constructor reproducible de paquetes
├── examples/leds_vhdl/           ejemplo VHDL con testbench
├── examples/leds_verilog/         ejemplo Verilog con testbench
├── examples/botones_leds_vhdl/   secuencias seleccionadas con pulsadores
├── examples/botones_leds_verilog/ mismo ejemplo escrito en Verilog
├── templates/project.json         plantilla de proyecto
└── docs/                           documentación
```

### Ejemplos con pulsadores

Los proyectos `botones_leds_vhdl` y `botones_leds_verilog` implementan el mismo comportamiento. Los botones son activos en nivel bajo:

| Entrada | Comportamiento de los LED |
|---|---|
| Ninguna | Un LED rebota entre ambos extremos. |
| `BTN1` | Un LED se desplaza de LED0 hacia LED3. |
| `BTN2` | Un LED se desplaza de LED3 hacia LED0. |
| `BTN3` | Los cuatro LED muestran un contador binario. |
| `BTN4` | Alterna los patrones `0101` y `1010`. |

Si se mantienen varios botones presionados, la prioridad es `BTN4`, `BTN3`, `BTN2` y `BTN1`. Cada proyecto contiene el fuente, el PCF y un testbench que comprueba los cinco modos.

El repositorio no versiona `downloads`, `tools`, `build` ni `backups`. Las herramientas se incorporan durante la construcción de cada Release y los resultados se generan localmente.

## Herramientas de terceros

Las distribuciones incluyen OSS CAD Suite 2026-10-28 y GHDL 6.0.0 obtenidos desde sus publicaciones oficiales y verificados mediante SHA-256. Consulte [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). La licencia MIT de este repositorio cubre únicamente los scripts y ejemplos propios.

## Seguridad de las descargas

No desactive Microsoft Defender ni agregue exclusiones. Verifique el SHA-256 publicado antes de ejecutar un archivo. El análisis de la alerta histórica `Trojan:Script/Wacatac.B!ml`, los resultados reproducibles y la forma de informar una detección están en [SECURITY.md](SECURITY.md).

## Limitaciones

- El instalador automático preparado es para Windows x64 y Linux x64.
- Un testbench Verilog debe generar su VCD/FST mediante `$dumpfile` y `$dumpvars` si se quiere abrir el diagrama.
- La síntesis VHDL utiliza el backend experimental de GHDL para generar una netlist Verilog.
- No se asume que un PCF sirve para cualquier diseño: los nombres de sus señales deben coincidir con los puertos del módulo o entidad superior.

## Solución de problemas

Consultar [docs/SOLUCION_PROBLEMAS.md](docs/SOLUCION_PROBLEMAS.md). Cada ejecución conserva `execution.log` dentro de su carpeta de salida.
