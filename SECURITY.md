# Seguridad

## Alcance de la respuesta

Este proyecto es una herramienta de escritorio que calcula un valor localmente.
No usa red propia, no almacena datos y no tiene superficie de ataque remota. El
enlace del pie abre el navegador sólo cuando lo clickeás.

Aun así, se agradecen reportes sobre:

- Comportamiento inesperado del ejecutable (llamadas de red, creación de
  procesos, escritura fuera de su directorio temporal).
- Problemas de integridad entre el binario publicado y el código fuente.
- Dependencias o mecanismos de compilación que puedan comprometer el artefacto.

Comportamientos esperados que **no** son vulnerabilidades:

- El loader de Inno ejecuta una copia temporal del propio binario.
- El modo CLI escribe únicamente el archivo de salida que se le indica.
- El enlace inferior abre el navegador a pedido (no hay red propia).

**No** se consideran vulnerabilidades:

- Que el DV permita obtener datos de un vehículo. Es el comportamiento
  esperado y está documentado en [DISCLAIMER.md](DISCLAIMER.md).
- Detecciones de antivirus heurísticas sobre binarios sin firmar. Ver la
  sección [Sobre los antivirus](README.md#sobre-los-antivirus).
- Errores de formato de dominio o valores DV distintos a los del sitio por
  cambios en AGIP: reportalo como bug normal.

## Cómo reportar

Por favor **no abras un issue público** para vulnerabilidades.

Usá [Report a vulnerability](https://github.com/mikear/DV/security/advisories/new)
de GitHub Security Advisories, o contactá a quien mantiene el proyecto de forma
privada.

Incluí:

- Versión del ejecutable (Propiedades del archivo → Detalles) y hash SHA-256.
- Pasos mínimos para reproducir.
- Impacto que creés que tiene.

## Respuesta esperada

| Plazo | Acción |
|---|---|
| 72 h | Acuse de recibo del reporte. |
| 7 días | Evaluación y, si procede, publicación de advisory. |
| 14 días | Corrección publicada en una nueva release. |

Si el reporte implica integridad del binario, se recomienda reconstruirlo desde
`dv-caba.iss` (en el paquete, `fuente/dv-caba.iss` con `fuente/iconos/`) y
comparar hashes antes de confiar en la build publicada.
