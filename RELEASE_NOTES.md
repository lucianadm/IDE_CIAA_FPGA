# IDE CIAA FPGA 1.1.0

Esta versión ofrece dos distribuciones para Windows x64 y Linux x64:

- **Completa:** contiene toda la toolchain y puede prepararse sin Internet.
- **Liviana:** descarga y verifica la toolchain durante la primera ejecución y luego la conserva localmente.

En Windows solo hay que extraer el paquete y ejecutar `IDE_CIAA_FPGA.bat`. En Linux se extrae el paquete y se ejecuta `./IDE_CIAA_FPGA.sh`. Los iniciadores verifican el entorno y preparan automáticamente las herramientas.

GTKWave carga automáticamente todas las señales simuladas y ajusta la vista al intervalo completo.

- Simulación VHDL 2008 y Verilog/SystemVerilog.
- Síntesis, asignación de pines, ruteo, análisis temporal y generación de bitstream para EDU-CIAA-FPGA.
- Programación opcional de la Flash mediante FT2232H.
- OSS CAD Suite 2026-10-28 y GHDL 6.0.0 incluidos; no se descargan componentes durante el uso.
- Ejemplos VHDL y Verilog con simulación.

Descargue el archivo correspondiente a su sistema y verifique su SHA-256 con `SHA256SUMS.txt`. El ZIP automático de **Source code** que agrega GitHub no contiene las herramientas.

La instalación del controlador WinUSB en Windows y de las reglas udev en Linux es una tarea separada y puede requerir permisos de administrador. El uso normal de la aplicación no los requiere.
