# Solución de problemas

## Windows no permite abrir el FT2232H

Compruebe en el Administrador de dispositivos:

- Interface 0 / `MI_00`: WinUSB, utilizada por `iceprog`.
- Interface 1 / `MI_01`: controlador FTDI, utilizada como COM si el diseño emplea UART.

No aplique WinUSB al dispositivo completo ni a `MI_01`. Si necesita usar Zadig, active **Options > List All Devices**, seleccione exclusivamente **Dual RS232-HS (Interface 0)** y verifique `USB ID 0403:6010`, interfaz `00`.

## Linux muestra `permission denied` o no abre el USB

Ejecute:

```bash
./scripts/linux/install_udev_rules.sh
```

Después cierre y abra la sesión. Algunas distribuciones también requieren pertenecer al grupo `plugdev`.

## El PCF informa señales no encontradas

El archivo PCF pertenece a otro diseño o los nombres no coinciden exactamente. Revise mayúsculas, minúsculas, índices de buses y el nombre del reloj.

## La simulación VHDL no termina

Use `std.env.stop` en el testbench y configure `simulation.stop_time`. El límite evita una ejecución indefinida, pero una simulación que llega al límite no prueba por sí sola que el testbench haya completado todas sus verificaciones.

## La simulación Verilog no genera diagrama

El testbench debe contener, por ejemplo:

```verilog
initial begin
    $dumpfile("top.vcd");
    $dumpvars(0, top_tb);
end
```

El mismo nombre debe aparecer en `simulation.wave_file`.

## GTKWave falla en Windows

El entorno intenta abrir primero Surfer. Puede abrir manualmente el archivo `.ghw`, `.vcd` o `.fst` guardado en `build` con otro visor compatible.

## La descarga es grande

OSS CAD Suite contiene síntesis, ruteo, simuladores, visores y programadores para varias familias. Si ya existe una instalación válida de Apio en Windows o todas las herramientas están instaladas en Linux, el iniciador las reutiliza.
