# Changelog

Todo notable de este proyecto queda documentado en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-1.1.0/),
y este proyecto adhería a [Versionado Semántico](https://semver.org/lang/es/).

## [1.0.0] - 2026-10-19

Primera release pública.

### Agregado

- **Ejecutable portátil** `dv-caba-portable.exe`: no instala nada, no muestra
  asistente, no deja desinstalador. `PrivilegesRequired=lowest`,
  `Uninstallable=no`, `CreateAppDir=no`.
- **Algoritmo DV reconstruido 1:1** de `patente.getDv()` (AGIP), verificado
  contra el original exportado desde el navegador: 432 casos y 1282
  comprobaciones.
- **Autotest interno**: el binario repite esa misma batería antes de abrir la
  ventana y se niega a ejecutarse si algo falla.
- **GUI nativa** escrita en Pascal Script sobre Inno Setup 6:
  campo de dominio con icono de copia, resultado grande con acceso de copia,
  línea de estado con glifo, enlace al sitio oficial y aviso de no oficialidad.
- **Modos de línea de comandos**: precarga del dominio, escritura del resultado
  a archivo y copia directa al portapapeles, con códigos de salida semánticos
  (0 = ok, 2 = error).
- **Portapapeles nativo**: sin invocar procesos externos; API de Win32
  (`OpenClipboard` / `SetClipboardData` / `GlobalAlloc`).
- **Icono propio multi-tamaño** (16 a 256 px) generado sin dependencias.
- **Documentación**: `README.md`, `ALGORITMO_DV.md` (paso a paso, ejemplo
  trabajado, IDs de evidencia, limitaciones), `DISCLAIMER.md` y `LICENSE` MIT.
- **Auditoría**: vectores dorados congelados en `test-paridad.js` para poder
  verificar el algoritmo sin disponer del JavaScript de AGIP.

### Notas de seguridad e integridad

- Sin conexiones de red.
- Sin procesos externos.
- Sin escritura fuera del directorio temporal del sistema.
