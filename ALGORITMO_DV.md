# Algoritmo del dígito verificador (DV) de patentes CABA

Documento técnico de la reconstrucción del DV que pide el sitio de AGIP
<https://lb.agip.gob.ar/ConsultaPat/> para consultar boletas de patentes de la
Ciudad Autónoma de Buenos Aires.

- **Origen del algoritmo**: `patente.getDv()` del archivo
  `https://lb.agip.gob.ar/libFe/js/patente.js`, servido públicamente por el
  propio sitio a todo navegador.
- **SHA-256 del archivo original**:
  `aaf9d4072b685fd5606d182d68fec8ec7cf99c12c28f89ee3bad2f59dbe0954e`
- **Implementación propia**: `dv.js` (reescritura limpia, no copia del original).
- **Verificación**: `test-paridad.js` compara ambas implementaciones en
  **432 casos / 1282 comprobaciones** y da OK (con los vectores dorados del
  paquete público, la misma batería aporta 432 comprobaciones). El `.exe`
  ejecuta además un autotest de humo —todas las letras y casos negativos— antes
  de abrir la GUI y antes del modo archivo.

## 1. Formatos de dominio aceptados

| Tipo | Regex del original | Ejemplo |
|---|---|---|
| Auto vieja | `^[A-Z]\d{7}$` | `A1234567` |
| Auto nueva | `^[A-Z]{3}\d{3}$` | `ABC123` |
| Moto nueva | `^\d{3}[A-Z]{3}$` | `123ABC` |
| Auto Mercosur | `^[A-Z]{2}\d{3}[A-Z]{2}$` | `QQ999QQ` |
| Moto Mercosur | `^[A-Z]\d{3}[A-Z]{3}$` | `A123BCD` |

El sitio valida contra estas cinco expresiones **antes** de calcular. Una patente
fuera de estas formas devuelve el mensaje "El dominio especificado no tiene un
formato válido." y no se calcula nada.

## 2. Tabla de letras

Cada letra se sustituye por un valor de dos dígitos:

```
A=14  B=01  C=00  D=16  E=05  F=20  G=19  H=09  I=24  J=07
K=21  L=08  M=04  N=13  O=25  P=22  Q=18  R=10  S=02  T=06
U=12  V=23  W=11  X=03  Y=15  Z=17   (espacio)=60
```

## 3. Pasos del cálculo

1. **Normalizar**: `patente.toUpperCase()`.
2. **Sustituir letras por la tabla**:
   - Si el dominio es formato **vieja** (`A1234567`), cada letra se reemplaza
     exactamente **una** vez por `"00"` (el resto son dígitos).
   - En cualquier otro formato, cada clave de la tabla se reemplaza hasta
     **4 veces** (una por ocurrencia), iterando la tabla completa.
3. **Control de longitud**: se exige que el resultado contenga una racha de
   **9 a 11 dígitos** (`/\d{9,11}/`). Si no, lanza
   *"No es válida la patente ingresada."*
4. **Suma por paridad**: se recorre el string resultante; los caracteres en
   índice **par** se suman en `a`, los de índice **impar** en `b`.
   (El índice es sobre la cadena ya sustituida, no sobre el dominio original.)
5. **Raíz digital**: a `a` y a `b` se les itera la suma de sus dígitos hasta
   que cada uno quede en un solo dígito.
6. **Resultado**: `parseInt(a ++ b)`, concatenando los dos dígitos finales.

## 4. Ejemplo trabajado: `QQ999QQ` → `99`

1. Formato Mercosur, no vieja → tabla de letras.
2. Sustitución: `Q=18` aparece 4 veces → `"18"+"18"+"9"+"9"+"9"+"18"+"18"` =
   `18189991818` (11 dígitos) ✓ pasa el control de longitud.
3. Suma por paridad sobre `18189991818`:
   - índices pares (0,2,4,6,8,10): `1+1+9+9+8+8` = **36** → `3+6` = **9**
   - índices impares (1,3,5,7,9): `8+8+9+1+1` = **27** → `2+7` = **9**
4. Concatenar: `9` y `9` → **DV = 99** ✓ (coincide con el sitio).

Más valores de referencia (todos verificados contra el original):

| Dominio | DV | Nota |
|---|---|---|
| `QQ999QQ` | 99 | Auto Mercosur |
| `ZZ999AA` | 17 | Auto Mercosur |
| `AB123CD` | 28 | Auto nueva |
| `ABC123` | 57 | Auto nueva |
| `A1234567` | 73 | Auto vieja |
| `123ABC` | 93 | Moto nueva |
| `A123BCD` | 37 | Moto Mercosur |
| `A0000000` | 0 | DV de un solo dígito |

## 5. Particularidades y limitaciones del original

Puntos no obvios que la reimplementación respeta a propósito (porque hay que
devolver exactamente los mismos valores que el sitio):

- **Reemplazo de primera ocurrencia**: JavaScript `String.replace(clave, valor)`
  con cadena reemplaza **sólo la primera** aparición. Por eso el original repite
  la llamada 4 veces (o 1 vez en formato vieja).
- **Regex sin anclas**: `/\d{9,11}/` no está anclada; detecta *cualquier* racha
  de 9 a 11 dígitos dentro del string, no necesariamente al final ni completa.
- **Índice de paridad sobre la cadena sustituida**: como cada letra vale dos
  dígitos, la posición de cada carácter cambia respecto del dominio original.
- **Riesgo de bucle infinito**: el original puede no terminar si `getDv` recibe
  una cadena con letras que no están en la tabla (p. ej. `Ñ`) y una racha de
  9+ dígitos: `parseInt('Ñ')` devuelve `NaN` y el `while` de raíz digital se
  repite para siempre. En el sitio eso es inalcanzable porque `validarCampos`
  llama a `valido()` antes que a `validoDv()`. Nuestra implementación
  (`calcularDV()`) reproduce ese mismo orden de validación para no exponer el
  problema.
- **Espacio mapeado a 60**: la tabla incluye `' ' -> '60'`, herencia del
  soporte de formatos con espacios que el sitio ya no ofrece en el formulario.
- **Sin verificación cruzada**: el original no valida que los dígitos de una
  posición concreta sean coherentes; cualquier dominio de la forma correcta
  produce un DV.

## 6. Evidencia (REA)

La reconstrucción se hizo con el MCP de REA sobre el sitio cargado en un
navegador real (Edge, UA de Chrome; el sitio bloquea `HeadlessChrome`).
Identificadores de evidencia del bundle (`evidence/rea-evidence-bundle.json`):

| Evidence ID | Operación |
|---|---|
| `ev_a4f2a661f79383d9c711e851b930fa756185a63b0dfde459d500fc7b0e481ea9` | `inspect_web_page` |
| `ev_be1f768f4f210585701c6e8d34fb437795d724ce9afca92c9ab1a11854a77d95` | `inspect_web_page` |
| `ev_c974b0ba0280e1c67d52500e07649a171cfceb95718eea78b796301fe7fe3a5f` | `inspect_web_page` |
| `ev_1e46e858b8369fd3c3d33a4b08f1c8c5aac151e1f5c12fe66591c3fd4e9adada` | `capture_browser_scenario` |
| `ev_b7cf82dc08fa6ae365879206001a54dd942242430d2aed3ac8482f9eb933b479` | `capture_browser_scenario` |
| `ev_717e364cd3aff6e7b33dd10b387c1a30fa8c8d94b60fa4552e364e2de319941a` | `list_browser_targets` |
| `ev_9ba92b1b180225f2547bd4601089a3ff8c2a0cef2aa9e37c081b703b7a2a8e9b` | `list_browser_targets` |

Limitación registrada: el trazado semántico de JavaScript de REA no aportó
aristas de llamada para el script (`trace_javascript_semantics`, 0 aristas), de
modo que la reconstrucción se apoyó en lectura estática del código servido y en
verificación numérica por paridad, no en un trazado dinámico.

## 7. Cómo reproducir la verificación

```bash
node dv.js QQ999QQ          # => DV: 99
node dv.js QQ999QQ AB123CD ABC123
node test-paridad.js        # 432 casos: 1282 checks con el original, 432 con dorados
```

`test-paridad.js` corre en dos modos:

- **con** el export del original en `web-scripts/files/**/libFe/js/patente.js`:
  paridad real contra los bytes servidos por AGIP.
- **sin** ese export (no se publica por ser código de terceros): compara contra
  los vectores dorados congelados dentro del propio test.

Para regenerar los vectores dorados en el entorno privado:

```bash
node test-paridad.js --dump-golden > golden.json
node tools/embed-golden.js embed
```

El `.exe` portátil ejecuta un autotest de humo (las 26 letras y casos
negativos) antes de abrir la GUI y antes del modo archivo; la batería completa
de 432 casos es la de `test-paridad.js`.

## 8. La chapa del dominio en la app

Desde la versión 1.1.0, la ventana dibuja la patente del dominio consultado.
La placa es **decorativa** (no interviene en el cálculo del DV):

- **Arte**: 5 fondos (`bg-vieja`, `bg-nacional`, `bg-mercosur`,
  `bg-moto-nacional`, `bg-moto-mercosur`) y glifos individuales por estilo:
  letras y dígitos con relieve, en PNG con transparencia. Viven en
  `iconos/chapas/` del repositorio y en `fuente/iconos/chapas/` del paquete.
- **Métricas**: avances, offsets y tamaños de cada glifo están en constantes
  CSV de `iconos/chapas/chapas-layout.iss`, incluido por el script de Inno
  Setup. La unidad es la centésima de placa (1/100 de la placa base).
- **Render**: en tiempo de ejecución el `.iss` extrae los PNG a `{tmp}`
  (`ExtractTemporaryFile`) y los pinta en `TBitmapImage` con alfa sobre el
  fondo; tras cerrar la app Inno limpia el temporal. No hay red ni procesos
  externos en ningún punto.
- **Estilos**: la forma del dominio (largo y posición de letras/dígitos)
  selecciona el fondo y el armado: vieja (letra grande + millón + 6 dígitos),
  nacional (letras+dígitos), Mercosur (2 grupos laterales + dígitos centrales)
  y las dos de moto en formato de dos filas.
- **Procedencia**: el arte es una reimplementación propia del diseño de las
  chapas argentinas (banda azul Pantone 286, guilloché, tipografía con
  relieve), generada con un exportador a PNG. La placa nacional 1995-2016
  lleva el **escudo nacional real** a color, integrado como PNG transparente
  desde la fuente del exportador (Wikimedia Commons, símbolo oficial en
  dominio público) y horneado en los fondos al exportar; el binario no lo lee
  en tiempo de ejecución y no hay red en ningún punto. Los agujeros de la
  banda Mercosur son las dos ranuras pasantes de la placa real (≈27% y ≈69%
  del ancho). El generador no es parte del
  paquete público; los PNG resultantes sí viajan para poder reconstruir y
  auditar el binario.
