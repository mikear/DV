# DV Patentes CABA — calculadora portátil del dígito verificador

Herramienta de escritorio, **portátil e instalable en cero pasos**, que calcula
localmente el dígito verificador (DV) que pide el sitio de AGIP para consultar
boletas de patentes de la Ciudad Autónoma de Buenos Aires.

- Sitio oficial de consulta: <https://lb.agip.gob.ar/ConsultaPat/>
- Autoría: **mikear** — <https://github.com/mikear/DV>
- Licencia: MIT (ver `LICENSE`)
- **No oficial**: sin afiliación con AGIP. Leé `DISCLAIMER.md` antes de usarla.

## Qué hace

El sitio de AGIP exige el DV para mostrar los datos del titular del vehículo.
El DV es una operación aritmética pura (tabla de letras + suma por paridad +
raíz digital) que este programa reproduce 1:1, **sin conexión a internet, sin
enviar datos y sin instalar nada**.

```
┌──────────────────────────────────────────────┐
│  DV Patentes CABA                            │
│  DOMINIO (PATENTE)   [ QQ999QQ ] [⧉] [Calcular]│
│  DIGITO VERIFICADOR  [   99     ] [⧉] [Copiar] │
│  ✓ Formato valido: copia "99" en el sitio AGIP. │
│  USALO EN EL SITIO  ↗ Abrir lb.agip.gob.ar/ConsultaPat/ │
└──────────────────────────────────────────────┘
```

## Descarga y verificación

1. Bajá `dv-caba-portable.exe` desde la release.
2. Verificá el hash antes de ejecutarlo:

```powershell
Get-FileHash .\dv-caba-portable.exe -Algorithm SHA256
```

Comparalo con el valor de `SHA256SUMS.txt` incluido en la release. Si no
coincide, **no lo ejecutes**.

## Uso

### Interfaz gráfica

Abrí el `.exe`. Escribí el dominio, apretá **Calcular**, y copiá el resultado
con el icono de la derecha o con **Copiar resultado**. También podés copiar el
dominio con el icono de al lado del campo. El enlace inferior abre el sitio
oficial en tu navegador.

### Línea de comandos

```
dv-caba.exe                     -> abre la app
dv-caba.exe QQ999QQ             -> app con el dominio precargado
dv-caba.exe QQ999QQ C:\r.txt    -> escribe "DV=99" y sale, exit 0 (ok) / 2 (error)
dv-caba.exe --copy 99           -> copia al portapapeles, exit 0 / 2
```

Un argumento que empieza con `/` nunca se interpreta como archivo de salida,
así que podés usar `/LOG=` de Inno sin que se rompa nada.

### Consola del navegador (en la página de AGIP)

Si preferís no salir del sitio, pegá `snippet-consola.js` en la consola
del navegador con la página abierta: rellena el campo del DV con el resultado.

### Versión de referencia en Node

```bash
node dv.js QQ999QQ          # => DV: 99
node dv.js QQ999QQ AB123CD ABC123
```

## Formatos aceptados

Auto vieja `A1234567` · auto nueva `ABC123` · moto nueva `123ABC` ·
auto Mercosur `QQ999QQ` · moto Mercosur `A123BCD`.

## Algoritmo

La reconstrucción completa está en [`ALGORITMO_DV.md`](ALGORITMO_DV.md), con el
paso a paso, un ejemplo trabajado, las particularidades del original y los IDs
de evidencia. Resumen:

1. Mayúsculas.
2. Sustitución de letras por tabla (`A=14 … Z=17`, `espacio=60`); en formato
   vieja las letras pasan a `00`.
3. Control de longitud: debe haber una racha de 9 a 11 dígitos.
4. Suma por paridad de índices (par → `a`, impar → `b`) sobre la cadena ya
   sustituida.
5. Raíz digital de `a` y de `b`.
6. `DV = parseInt(a ++ b)`.

## Auditoría y reproducibilidad

Este paquete incluye el código fuente para que puedas verificar que el binario
no hace nada raro:

- `fuente/dv-caba.iss` — script de Inno Setup 6 que genera el `.exe`. La GUI es
  Pascal Script nativo; **no ejecuta procesos externos** (el portapapeles se
  maneja con API de Win32: `user32`/`kernel32`).
- `fuente/dv.js` — implementación de referencia del algoritmo.
- `fuente/test-paridad.js` — batería de 432 casos / 1282 comprobaciones.
- `ALGORITMO_DV.md`, `DISCLAIMER.md`, `LICENSE`.

Para reconstruir el binario necesitás [Inno Setup 6](https://jrsoftware.org/isinfo.php):

```powershell
iscc.exe fuente\dv-caba.iss
```

Para correr los tests:

```bash
node test-paridad.js
```

### Qué NO incluye el paquete

No incluye el JavaScript original de AGIP (es código de terceros) ni ningún
archivo de evidencia. El test corre contra vectores dorados congelados, que
fueron generados y verificados contra el original en el entorno privado de
ingeniería inversa.

## Nota sobre antivirus (McAfee / SmartScreen)

Algunos antivirus señalan binarios desconocidos, sin firmar y empaquetados con
heurística en la nube. Es un **falso positivo** típico (`Artemis!`), no una
detección de comportamiento malicioso. El binario no hace red, no ejecuta
procesos y no instala nada: podés verificarlo con el hash y reconstruyéndolo
desde la fuente.

Recomendaciones:

- Para pedir la revisión del falso positivo:
  [Microsoft Security Intelligence](https://www.microsoft.com/wdsi/filesubmission)
  y [McAfee Threat Submission](https://www.mcafee.com/us/consumer-support/other-threats/false-positive-reporting.html).
- **No subas el archivo a VirusTotal** antes de ese trámite: VT comparte las
  muestras con todos los fabricantes y puede consolidar la detección en vez de
  levantarla.
- La solución definitiva es firmar el ejecutable con un certificado OV/EV.

## Privacidad

- No abre conexiones de red.
- No recolecta ni envía datos.
- No escribe en el registro ni instala nada; es un ejecutable portátil.
- El resultado se calcula en tu máquina a partir del texto que tipeás.

## Aviso legal

Herramienta no oficial, sin afiliación con AGIP. El DV es informativo: AGIP
expresa que su consulta "carece de valor documental alguno". Al aportar el DV,
el sitio puede devolver datos personales del titular (nombre y dirección), por
lo que este software debe usarse **sólo con fines lícitos** y conforme a la
Ley 25.326 de Protección de Datos Personales.

Texto completo en [`DISCLAIMER.md`](DISCLAIMER.md).
