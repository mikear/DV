# Contribuir a DV Patentes CABA

Gracias por querer contribuir. Este proyecto es chico y deliberadamente
simple: mantenerlo simple es parte del objetivo.

## Empezá por acá

1. Abrí un [issue](https://github.com/mikear/DV/issues) antes de escribir
   código grande. Así evitamos trabajo duplicado.
2. Para bugs, usá la plantilla correspondiente y adjuntá la salida de
   `node test-paridad.js` si es posible.

## Flujo de trabajo

```bash
git clone https://github.com/TU_USUARIO/DV.git
cd DV
node test-paridad.js       # debe pasar antes de tocar nada
```

1. Creá un fork y una rama: `git checkout -b mejora/mi-cambio`.
2. Hacé el cambio.
3. Corré los tests: `node test-paridad.js`.
4. Abrí un pull request describiendo **qué** cambió y **por qué**.

## Reglas del proyecto

- **El algoritmo debe seguir coincidiendo con AGIP.** Si cambiás la lógica del
  DV, agregá los vectores de prueba que lo respalden. Es el criterio que no se
  negocia.
- **Sin dependencias.** Ni en el `.exe` ni en los scripts de Node. Todo con la
  biblioteca estándar.
- **Sin procesos externos desde el `.exe`.** El portapapeles se maneja con API
  de Win32; no se invoca `cmd`, `powershell` ni nada equivalente.
- **Sin conexión a red.** Si algún cambio requiere red, discutilo primero en un
  issue.
- **Sin emojis en la interfaz.** Los glifos van con Segoe MDL2 Assets.
- **Código de AGIP no se sube.** Ni el JavaScript original ni capturas de
  páginas con datos de contribuyentes.

## Estructura

| Archivo | Qué hay |
|---|---|
| `dv-caba.iss` | Script de Inno Setup 6: CLI, GUI en Pascal Script, Win32. |
| `dv.js` | Implementación de referencia del algoritmo. |
| `test-paridad.js` | Batería de 432 casos y vectores dorados. |
| `snippet-consola.js` | Utilidad para la consola del navegador. |
| `tools/make-icon.js` | Generador del `.ico` (sin dependencias). |
| `tools/embed-golden.js` | Regenera los vectores dorados del test. |

## Compilar el ejecutable

Necesitás [Inno Setup 6](https://jrsoftware.org/isinfo.php):

```powershell
iscc.exe dv-caba.iss
```

El binario corre su propio autotest antes de abrir la GUI; si un vector falla,
no abre y sale con código 2.

## Estilo

- Comentarios y mensajes de la GUI en **español**, sin acentos en el código de
  Inno (el compilador trabaja en la codificación del sistema).
- Nombres en inglés para variables y funciones, como ya está en el proyecto.
- Preferí claridad sobre astucia: este código lo tiene que leer alguien que
  audita.

## Licencia

Al contribuir, aceptás que tu aporte se distribuya bajo [licencia MIT](LICENSE).
