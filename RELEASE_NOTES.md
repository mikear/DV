# DV Patentes CABA v1.1.1

<img src="https://raw.githubusercontent.com/mikear/DV/main/docs/screenshot.png" alt="Aplicación calculando el dígito verificador de AB123CD con la chapa del dominio dibujada" width="560">

Calculadora **portátil** del dígito verificador (DV) de patentes de la Ciudad
Autónoma de Buenos Aires, usado por el sitio de AGIP:
<https://lb.agip.gob.ar/ConsultaPat/>

Hecha por **[mikear](https://github.com/mikear/DV)**. Código fuente:
<https://github.com/mikear/DV>.

**No oficial. Sin afiliación con AGIP.** Ver `DISCLAIMER.md`.

## Novedades de 1.1.1

### Escudo argentino real en la placa pre-2016

- La placa nacional (1995-2016, con banda "ARGENTINA") lleva ahora el **escudo
  argentino auténtico a color** — sol de mayo, laureles, gorro frigio — en
  vez del emblema esquemático. También en la placa de moto. El PNG transparente
  queda horneado en el arte embebido: la app no abre red ni lee archivos.

### Agujeros de la banda Mercosur corregidos

- El estilo Mercosur (2016+) dibuja ahora las **dos ranuras blancas pasantes**
  del borde superior de la banda, en la posición real de la placa (~27% y ~69%
  del ancho). Antes había una sola, desplazada: el agujero de la mitad
  celeste superior quedaba tapado por la zona de la bandera. Auto y moto.

## Novedades de 1.1.0

### Chapa del dominio

- La ventana ahora dibuja **la patente del dominio consultado** en el estilo
  correcto, entre el dígito verificador y la ayuda:

  | formato | ejemplo | placa |
  |---|---|---|
  | auto vieja | `A1234567` | placa negra, letra grande + fila de dígitos |
  | auto nacional | `ABC123` | placa blanca con banda y garantía |
  | auto Mercosur | `AB123CD` | placa argentina con banda azul y guilloché |
  | moto nacional | `123ABC` | placa chica de moto |
  | moto Mercosur | `A123BCD` | placa chica de moto con banda Mercosur |

- El arte viaja embebido en el `.exe`: fondos y glifos PNG con transparencia,
  pintados por la GUI con alpha nativo. No hay red, no hay dependencias y no
  hay procesos externos.
- Con un formato inválido la chapa queda oculta y no se calcula el DV.
- La ventana es algo más alta; la captura pasa a 560×619.
- El ejecutable crece de ~2 MB a ~3,2 MB porque incluye el arte de las chapas.

## Qué incluye

- `dv-caba-portable.exe` — ejecutable portátil. **No es un instalador**: no
  muestra asistente, no instala nada, no deja desinstalador.
- `SHA256SUMS.txt` — hash SHA-256 de cada archivo del paquete.
- `README.md` — uso (GUI, línea de comandos, consola del navegador).
- `ALGORITMO_DV.md` — reconstrucción del algoritmo paso a paso, con ejemplo
  trabajado, particularidades del original y los IDs de evidencia.
- `DISCLAIMER.md` — aviso legal completo.
- `LICENSE` — MIT.
- `fuente/` — código fuente completo para auditar y reconstruir el binario
  (incluye `fuente/iconos/`, con el arte de las chapas en `fuente/iconos/chapas/`).

## Ejemplo

`AB123CD` → **DV 28**. Escribí el dominio, apretá Calcular y copiá el resultado.
Mirá la placa dibujada en la sección "Chapa del dominio".

**Requisitos:** Windows 10 1607 o superior (Windows 11 incluido).

## Características

- **Cero red**: la app no abre conexiones propias, no envía ni recolecta datos.
  El enlace del pie abre el navegador cuando lo clickeás.
- **Cero procesos externos**: el portapapeles se maneja con API nativa de Win32
  (`user32`/`kernel32`), sin invocar `cmd` ni `powershell`.
- **Cero instalación**: `Uninstallable=no`, `CreateAppDir=no`,
  `PrivilegesRequired=lowest`. El proceso cierra con `ExitProcess(0)`.
- **Autotest interno de humo**: antes de abrir la ventana (y antes del modo
  archivo) corre un autotest con las 26 letras y casos negativos. La batería
  completa de 432 casos está en `fuente/test-paridad.js`.
- Icono propio multi-tamaño, GUI nativa en Pascal Script, tipografía y glifos
  de Segoe MDL2 Assets (sin emojis).

## Uso rápido

```
dv-caba-portable.exe                     -> abre la app
dv-caba-portable.exe AB123CD             -> app con el dominio precargado
dv-caba-portable.exe AB123CD C:\r.txt    -> escribe "DV=28" y sale (exit 0 / 2)
dv-caba-portable.exe --copy 28           -> copia al portapapeles (exit 0 / 2)
```

## Verificación

```powershell
Get-FileHash .\dv-caba-portable.exe -Algorithm SHA256
```

Comparar con `SHA256SUMS.txt`. Para reconstruir desde la fuente hace falta
[Inno Setup 7](https://jrsoftware.org/isinfo.php):

```powershell
iscc.exe fuente\dv-caba.iss
```

Para correr la batería completa:

```bash
node fuente/test-paridad.js
```

## Cambios anteriores

- **1.1.0** — chapa del dominio: la ventana dibuja la patente en el estilo
  correcto (5 estilos), arte embebido con transparencia, sin red.
- **1.0.3** — jerarquía de acciones y copia simplificada; validación junto al
  campo; README reorganizado con badges y FAQ.
- **1.0.2** — autoría visible en la ventana y en los metadatos del ejecutable.
- **1.0.1** — paquete reconstruible (`fuente/iconos/` viaja en el zip),
  autotest ampliado, modo archivo con exit 2, paridad estricta con espacios.
- **1.0.0** — primera release pública: algoritmo reconstruido 1:1 (432 casos,
  1282 comprobaciones), GUI nativa, modos CLI, portapapeles nativo, icono
  propio y documentación completa.

## Sobre el antivirus

Algunos antivirus señalan binarios desconocidos y sin firmar (heurística en la
nube, p. ej. `Artemis!`). Es un **falso positivo** típico: el binario no hace
red, no invoca `cmd`/`powershell` para el cálculo y no instala nada. Podés
verificar el hash y reconstruir el ejecutable desde `fuente/`.

No subas el archivo a VirusTotal antes de pedir la revisión al fabricante: VT
comparte las muestras y puede consolidar la detección.
