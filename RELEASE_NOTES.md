# DV Patentes CABA v1.0.0

<img src="https://raw.githubusercontent.com/mikear/DV/main/docs/screenshot.png" alt="Aplicación calculando el dígito verificador de AB123CD" width="560">

Calculadora **portátil** del dígito verificador (DV) de patentes de la Ciudad
Autónoma de Buenos Aires, usado por el sitio de AGIP:
<https://lb.agip.gob.ar/ConsultaPat/>

**No oficial. Sin afiliación con AGIP.** Ver `DISCLAIMER.md`.

## Qué incluye

- `dv-caba-portable.exe` — ejecutable portátil. **No es un instalador**: no
  muestra asistente, no instala nada, no deja desinstalador.
- `SHA256SUMS.txt` — hash SHA-256 de cada archivo del paquete.
- `README.md` — uso (GUI, línea de comandos, consola del navegador).
- `ALGORITMO_DV.md` — reconstrucción del algoritmo paso a paso, con ejemplo
  trabajado, particularidades del original y los IDs de evidencia.
- `DISCLAIMER.md` — aviso legal completo.
- `LICENSE` — MIT.
- `fuente/` — código fuente completo para auditar y reconstruir el binario.

## Ejemplo

`AB123CD` → **DV 28**. Escribí el dominio, apretá Calcular, copiá el resultado.

## Características

- **Cero red**: no abre conexiones, no envía ni recolecta datos.
- **Cero procesos externos**: el portapapeles se maneja con API nativa de Win32
  (`user32`/`kernel32`), sin invocar `cmd` ni `powershell`.
- **Cero instalación**: `Uninstallable=no`, `CreateAppDir=no`,
  `PrivilegesRequired=lowest`. El proceso cierra con `ExitProcess(0)`.
- **Autotest interno**: antes de abrir la ventana corre la misma batería de
  432 casos / 1282 comprobaciones que `test-paridad.js`; si algo falla, no abre.
- Icono propio multi-tamaño, GUI nativa en Pascal Script, tipografía y glifos
  de Segoe MDL2 Assets (sin emojis).

## Uso rápido

```
dv-caba.exe                     -> abre la app
dv-caba.exe QQ999QQ             -> app con el dominio precargado
dv-caba.exe QQ999QQ C:\r.txt    -> escribe "DV=99" y sale (exit 0 / 2)
dv-caba.exe --copy 99           -> copia al portapapeles (exit 0 / 2)
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

## Sobre el antivirus

Algunos antivirus señalan binarios desconocidos y sin firmar (heurística en la
nube, p. ej. `Artemis!`). Es un **falso positivo** típico: el binario no hace
red, no ejecuta procesos y no instala nada. Podés verificar el hash y
reconstruir el ejecutable desde `fuente/`.

No subas el archivo a VirusTotal antes de pedir la revisión al fabricante: VT
comparte las muestras y puede consolidar la detección.
