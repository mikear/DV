# DV Patentes CABA v1.0.3

<img src="https://raw.githubusercontent.com/mikear/DV/main/docs/screenshot.png" alt="Aplicación calculando el dígito verificador de AB123CD" width="560">

Calculadora **portátil** del dígito verificador (DV) de patentes de la Ciudad
Autónoma de Buenos Aires, usado por el sitio de AGIP:
<https://lb.agip.gob.ar/ConsultaPat/>

Hecha por **[mikear](https://github.com/mikear/DV)**. Código fuente:
<https://github.com/mikear/DV>.

**No oficial. Sin afiliación con AGIP.** Ver `DISCLAIMER.md`.

## Cambios de 1.0.3

### Interfaz

- **Calcular como acción principal**: más grande y en negrita.
- **Resultado protagonista**: el DV se muestra centrado y con mayor tamaño.
- **Copia simplificada**: se quitó el icono duplicado del resultado y
  `Copiar resultado` se habilita recién cuando hay un DV.
- **Validación junto al campo**: los estados y errores aparecen debajo del
  dominio; si el formato es inválido, el foco vuelve al campo.
- **Textos y legibilidad**: tildes y voseo consistentes, textos secundarios de
  9 pt con más contraste, y aviso de herramienta no oficial y cálculo local más
  visible.
- **Enlaces más claros**: el acceso al sitio de AGIP muestra una etiqueta corta
  y la URL completa queda en el tooltip.

### Documentación

- README y captura de la app actualizados.
- Changelog con las novedades de la versión.

## Cambios de 1.0.2

- Autoría visible en la ventana: pie con enlace clickeable al repositorio.
- La URL del repositorio figura en las propiedades del ejecutable.
- README y DISCLAIMER con la autoría y el enlace a GitHub.

## Cambios de 1.0.1

- El paquete ahora incluye `fuente/iconos/` y se puede reconstruir desde el zip.
- El autotest del binario cubre las 26 letras y casos negativos.
- El modo archivo devuelve exit 2 si no puede escribir el resultado.
- El cálculo es estricto con espacios (igual que `patente.valido`); la GUI
  normaliza el campo antes de calcular.
- La GUI limpia el resultado al editar el dominio y el icono de copiar
  resultado ya es clickeable.
- El snippet de consola valida antes de llamar a `getDv` y normaliza el campo.
- Documentación corregida: formatos, ejemplo completo, nombres del ejecutable,
  modos del test y requisito Windows 10 1607+.

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
  (incluye `fuente/iconos/`).

## Ejemplo

`AB123CD` → **DV 28**. Escribí el dominio, apretá Calcular, copiá el resultado.

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
dv-caba-portable.exe QQ999QQ             -> app con el dominio precargado
dv-caba-portable.exe QQ999QQ C:\r.txt    -> escribe "DV=99" y sale (exit 0 / 2)
dv-caba-portable.exe --copy 99           -> copia al portapapeles (exit 0 / 2)
```

## Verificación

```powershell
Get-FileHash .\dv-caba-portable.exe -Algorithm SHA256
```

Comparar con `SHA256SUMS.txt`. Para reconstruir desde la fuente hace falta
[Inno Setup 6](https://jrsoftware.org/isinfo.php):

```powershell
iscc.exe fuente\dv-caba.iss
```

Para correr la batería completa:

```bash
node fuente/test-paridad.js
```

## Sobre el antivirus

Algunos antivirus señalan binarios desconocidos y sin firmar (heurística en la
nube, p. ej. `Artemis!`). Es un **falso positivo** típico: el binario no hace
red, no invoca `cmd`/`powershell` para el cálculo y no instala nada. Podés
verificar el hash y reconstruir el ejecutable desde `fuente/`.

No subas el archivo a VirusTotal antes de pedir la revisión al fabricante: VT
comparte las muestras y puede consolidar la detección.
