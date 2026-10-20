# Changelog

Todo notable de este proyecto queda documentado en este archivo.

El formato se basa en [Keep a Changelog](https://keepachangelog.com/es-1.1.0/),
y este proyecto adhería a [Versionado Semántico](https://semver.org/lang/es/).

## [1.0.2] - 2026-10-20

### Agregado

- **Autoría visible en la app**: el pie de la ventana muestra
  `Hecho por mikear - github.com/mikear/DV` con enlace clickeable al
  repositorio.
- **Metadatos del ejecutable**: `VersionInfoCopyright` incluye la URL del
  repositorio; se agregaron `AppPublisherURL`, `AppSupportURL` y
  `AppUpdatesURL`.
- **Documentación**: línea de autoría con enlace a GitHub en `README.md` y
  `DISCLAIMER.md`.

## [1.0.1] - 2026-10-19

### Corregido

- **Paquete reproducible**: `fuente/iconos/` ahora viaja en el zip; `fuente/dv-caba.iss`
  compila sin depender de la carpeta `iconos/` del repositorio.
- **Autotest del binario ampliado**: cubre las 26 letras de la tabla y casos
  negativos (formatos inválidos, espacios, `Ñ`, minúsculas y mixtas). La
  batería completa de 432 casos sigue en `test-paridad.js`.
- **Modo archivo**: si `SaveStringToFile` falla, el proceso sale con código 2
  (antes salía con 0 sin haber escrito nada).
- **Paridad estricta**: se quitó `Trim` del núcleo de cálculo; un dominio con
  espacios se rechaza igual que en `patente.valido`. La GUI normaliza el campo
  antes de calcular para comodidad del usuario.
- **GUI**: el resultado se limpia al editar el dominio, el icono de copiar
  resultado ahora es clickeable, `Esc` cierra la ventana y el foco arranca en
  el campo de dominio. El aviso legal tiene mejor contraste.
- **Snippet de consola**: valida con `patente.valido` antes de llamar a
  `getDv` (evita el bucle del original con `Ñ` y 9+ dígitos) y normaliza el
  campo antes de calcular.
- **Documentación**: requisito Windows 10 1607+, nombres reales del ejecutable,
  tabla de formatos corregida, ejemplo del algoritmo completo y aclaración de
  los dos modos del test (432/1282 vs. 432/432).

### Notas de seguridad e integridad

- El loader de Inno ejecuta una copia temporal del propio binario.
- El modo CLI escribe únicamente el archivo de salida indicado.
- No hay conexiones de red propias; el enlace del pie abre el navegador a pedido.

## [1.0.0] - 2026-10-19

Primera release pública.

### Agregado

- **Ejecutable portátil** `dv-caba-portable.exe`: no instala nada, no muestra
  asistente, no deja desinstalador. `PrivilegesRequired=lowest`,
  `Uninstallable=no`, `CreateAppDir=no`.
- **Algoritmo DV reconstruido 1:1** de `patente.getDv()` (AGIP), verificado
  contra el original exportado desde el navegador: 432 casos y 1282
  comprobaciones.
- **Autotest interno de humo**: en 1.0.0 eran 12 vectores; en 1.0.1 cubre las
  26 letras y casos negativos. Se ejecuta antes de la GUI y del modo archivo.
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

- Sin conexiones de red propias (el enlace abre el navegador a pedido).
- Sin invocar `cmd` ni `powershell`; el portapapeles usa API de Win32.
- Sin escritura fuera del temporal, salvo el archivo de salida explícito del
  modo CLI.
