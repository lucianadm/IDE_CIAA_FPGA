# Seguridad y descargas

## Archivos oficiales

Las distribuciones ejecutables se publican únicamente en **Releases**:

- `IDE_CIAA_FPGA_<version>_Windows_x64_Completa.zip`
- `IDE_CIAA_FPGA_<version>_Windows_x64_Liviana.zip`
- `IDE_CIAA_FPGA_<version>_Linux_x64_Completa.tar.gz`
- `IDE_CIAA_FPGA_<version>_Linux_x64_Liviana.tar.gz`
- `SHA256SUMS.txt`

El botón **Code > Download ZIP** descarga solamente el código fuente. No contiene las herramientas y no debe presentarse como versión instalable.

Antes de ejecutar un paquete, compare su SHA-256 con `SHA256SUMS.txt`. En Windows puede usar:

```powershell
Get-FileHash .\IDE_CIAA_FPGA_*_Windows_x64.zip -Algorithm SHA256
```

No se recomienda desactivar Microsoft Defender ni agregar exclusiones. Si un antivirus informa una detección, conserve el nombre exacto, la versión de firmas, el SHA-256 del archivo y el origen de la descarga, y abra un issue sin adjuntar datos privados.

## Análisis del 1 de noviembre de 2026

Se verificaron con Microsoft Defender, firmas `1.463.79.0`, el ZIP de código generado por GitHub y los cuatro archivos oficiales usados para construir las distribuciones. No se detectaron amenazas. Por lo tanto, la detección histórica `Trojan:Script/Wacatac.B!ml` (`ThreatID 2147735503`) no pudo reproducirse ni asociarse a un archivo concreto con esas firmas.

El problema confirmado del esquema anterior era distinto: los binarios estaban registrados con Git LFS, de modo que el ZIP de código de GitHub contenía punteros en lugar de los paquetes reales. Las distribuciones actuales se construyen como assets independientes y se prueban después de extraerlas. Las ediciones completas contienen la toolchain; las livianas descargan los mismos paquetes oficiales y verifican su SHA-256 antes de extraerlos.

## Reporte responsable

Para informar una vulnerabilidad que no deba hacerse pública, use la opción privada **Security > Report a vulnerability** del repositorio. Para fallos comunes de compilación o instalación, use Issues.
