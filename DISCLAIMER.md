# Disclaimer

**DV Patentes CABA** es una herramienta **no oficial**. No está creada, respaldada,
patrocinada ni afiliada por la **AGIP** (Administración Gubernamental de Ingresos
Públicos de la Ciudad Autónoma de Buenos Aires), ni por ninguna autoridad pública.

Sitio oficial y único autorizado: <https://lb.agip.gob.ar/ConsultaPat/>

## Qué hace y qué no hace

- **Hace**: calcula localmente, en tu computadora, el dígito verificador (DV) que
  el sitio de AGIP pide al consultar boletas de patentes. Es una operación
  aritmética (tabla de letras + suma por paridad + raíz digital). No hay red.
- **No hace**: no consulta el sitio de AGIP, no descarga ni almacena datos de
  contribuyentes, no automatiza trámites, no evade captcha ni controles de acceso,
  no envía información a ningún servidor, no instala nada en el sistema.

## Sobre el dato que obtenés al usar el DV

AGIP advierte en su propio sitio:

> "Por resguardo del secreto fiscal, las boletas obtenidas sin dígito verificador
> no contendrán los datos del contribuyente (nombre y dirección)."

Es decir: el DV es una **salvaguarda de privacidad**. Al proporcionarlo, el sitio
puede devolver **datos personales de una persona** (nombre y dirección del
titular del vehículo). Por lo tanto:

- Usá esta herramienta **sólo con fines lícitos** y propios o legítimamente
  autorizados (por ejemplo, verificar tu propio vehículo o una investigación
  debidamente habilitada).
- Los datos personales obtenidos están regidos por la **Ley 25.326 de Protección
  de Datos Personales** (Argentina). Queda prohibido su uso para hostigamiento,
  persecución, suplantación, fraude o cualquier finalidad ilícita.
- El autor no se responsabiliza del uso que se dé a la información obtenida por
  terceros con esta herramienta.

## Validez del resultado

- El DV calculado es **informativo**. AGIP expresa que su consulta "carece de
  valor documental alguno". Un resultado correcto de esta herramienta **no
  acredita** deuda, pago, titularidad ni ninguna otra situación fiscal.
- El algoritmo fue reconstruido a partir del código que el propio sitio sirve a
  todo navegador. Si AGIP lo modifica, el resultado podría dejar de coincidir:
  verificá siempre en el sitio oficial.

## Uso del software

Se distribuye **tal cual**, sin garantía de ningún tipo, expresa o implícita,
incluidas garantías de comerciabilidad, idoneidad para un fin concreto o
infracción. El autor no será responsable de daños derivados del uso o de la
imposibilidad de uso de esta herramienta.

Lee además `README.md` y la licencia `LICENSE`.
