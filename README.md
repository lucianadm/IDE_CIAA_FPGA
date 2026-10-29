# IDE CIAA FPGA

Entorno reproducible para trabajar con la **EDU-CIAA-FPGA** desde Windows o Linux. Permite:

- simular diseños Verilog/SystemVerilog con Icarus Verilog;
- simular VHDL 2008 con GHDL;
- abrir diagramas temporales con Surfer o GTKWave;
- sintetizar con Yosys;
- asignar pines y rutear con nextpnr-ice40;
- generar bitstreams con IceStorm;
- mostrar y guardar un informe de utilización y frecuencia máxima;
- identificar, respaldar, programar y comparar la Flash con `iceprog`.

El repositorio completo incluye en `downloads` los paquetes oficiales necesarios para Windows y Linux. Después de clonarlo con Git LFS, puede instalar y ejecutar las herramientas sin conexión. El iniciador comprueba lo disponible, reutiliza los paquetes locales y solo intenta descargar algo si el archivo correspondiente falta o no supera la verificación SHA-256.

> Para una copia realmente autocontenida no use el botón **Download ZIP** de GitHub. Clone el repositorio con Git LFS o descargue una publicación que incluya los binarios completos. Los archivos señalados por Git LFS deben descargarse mientras todavía haya conexión.

## Sistemas admitidos

- Windows 10 u 11 x64, procesador Intel o AMD.
- Linux x64, procesador Intel o AMD.

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

1. Descargar o clonar esta carpeta en una ruta sin caracteres extraños. No requiere una ubicación fija.
2. Ejecutar `IDE_CIAA_FPGA.bat`.
3. Leer el cartel inicial y elegir VHDL o Verilog/SystemVerilog.
4. Seleccionar juntos todos los archivos sintetizables del diseño e indicar inmediatamente el top level.
5. Responder si se quiere ejecutar la simulación funcional RTL. El testbench se solicita solamente cuando la respuesta es afirmativa.
6. Revisar el diagrama temporal, que se abre automáticamente si la simulación termina correctamente.
7. Seleccionar el archivo PCF, sintetizar, rutear y generar el bitstream. Para llegar hasta este punto no es necesario conectar la placa.
8. Revisar el informe de síntesis y elegir `Programar FPGA` o `No programar`. Solo la primera opción intenta acceder al dispositivo.

El selector admite varios archivos tanto para el diseño como para el testbench. La primera simulación es funcional RTL y no necesita el PCF. Después de una simulación correcta abre automáticamente el diagrama temporal. En VHDL también pregunta la duración máxima. En Verilog agrega un envoltorio de simulación que genera el archivo VCD aunque el testbench no incluya `$dumpfile` y `$dumpvars`. Se conservan los comandos de consola para automatizar el flujo mediante un `project.json`.

El diagrama temporal de la simulación RTL no contiene los retardos físicos del FPGA. Durante el ruteo, nextpnr realiza análisis temporal estático y comprueba si el diseño cumple la frecuencia indicada en `frequency_mhz`. Este flujo no genera una simulación post-ruteo con retardos anotados.

Al finalizar la síntesis se muestra un resumen con celdas lógicas, bloques de RAM, entradas/salidas, buffers globales, PLL, tamaño del bitstream y frecuencia máxima de cada reloj. En el asistente de Windows aparece una ventana con el informe completo y los botones `Programar FPGA` y `No programar`. El informe y el `.bin` se copian con fecha y hora junto al archivo que contiene el top level; también permanecen en la carpeta interna `build`.

Si la copia incluye `downloads`, la primera ejecución extrae OSS CAD Suite y GHDL localmente sin acceder a Internet. Si esos paquetes fueron eliminados, puede descargar aproximadamente 600 MB para OSS CAD Suite y 24 MB para GHDL. Si encuentra una instalación válida de Apio, también puede reutilizarla.

Para usar la placa, **FT2232H Interface A / MI_00** debe tener WinUSB. **Interface B / MI_01** debe conservar el controlador FTDI si se utilizará como puerto UART. El entorno nunca cambia controladores automáticamente.

## Inicio rápido en Linux

Dar permiso de ejecución una sola vez:

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

`downloads` contiene los instaladores verificados para poder preparar otra computadora sin conexión. `tools` y `build` se conservan también en la distribución completa. `backups` permanece excluida porque puede contener el diseño previo leído de una placa particular.

## Herramientas de terceros

Los instaladores descargan OSS CAD Suite de YosysHQ y GHDL desde sus repositorios oficiales. Esos proyectos conservan sus propias licencias. La licencia MIT de este repositorio cubre únicamente los scripts y ejemplos incluidos aquí.

## Limitaciones

- El instalador automático preparado es para Windows x64 y Linux x64.
- Un testbench Verilog debe generar su VCD/FST mediante `$dumpfile` y `$dumpvars` si se quiere abrir el diagrama.
- La síntesis VHDL utiliza el backend experimental de GHDL para generar una netlist Verilog.
- No se asume que un PCF sirve para cualquier diseño: los nombres de sus señales deben coincidir con los puertos del módulo o entidad superior.

## Solución de problemas

Consultar [docs/SOLUCION_PROBLEMAS.md](docs/SOLUCION_PROBLEMAS.md). Cada ejecución conserva `execution.log` dentro de su carpeta de salida.
