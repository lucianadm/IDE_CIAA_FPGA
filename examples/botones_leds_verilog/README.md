# Botones y secuencias de LED en Verilog

Ejemplo para la EDU-CIAA-FPGA con reloj de 12 MHz. Los pulsadores son activos en nivel bajo.

- Sin pulsar: rebote de un LED entre los extremos.
- `BTN1`: desplazamiento de LED0 hacia LED3.
- `BTN2`: desplazamiento de LED3 hacia LED0.
- `BTN3`: contador binario de cuatro bits.
- `BTN4`: alternancia `0101/1010`.

El diseño sincroniza cada pulsador con dos registros antes de utilizarlo. El parámetro `CICLOS_POR_PASO` controla la velocidad; el valor de placa produce un cambio cada 250 ms.

Compilar y simular desde la raíz:

```bat
IDE_CIAA_FPGA.bat build examples\botones_leds_verilog\project.json --simulate --view
```
