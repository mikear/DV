/**
 * SNIPPET DE CONSOLA - Dígito verificador de patentes CABA (AGIP)
 * ---------------------------------------------------------------
 * Uso:
 *   1) Abrí https://lb.agip.gob.ar/ConsultaPat/
 *   2) Cargá el Dominio (ej. AB123CD) en el primer campo.
 *   3) F12 -> pestaña Consola -> pegar este bloque -> Enter.
 *
 * Resultado: tilda "Cuento con el dígito verificador", abre ese campo
 * y lo completa. El captcha lo tenés que resolver a mano.
 *
 * Usa la función nativa de la página (patente.getDv), así que no hay
 * desfase posible con el sitio. Alternativa sin depender de la página:
 * ver CALCULAR_DOMINIO_ABAJO.
 */
(() => {
  const $ = window.jQuery;
  if (!$) { console.error('jQuery no disponible'); return; }

  const $dom = $('#fldDominio');
  const dominio = ($dom.val() || '').trim().toUpperCase();
  if (!dominio) { alert('Cargá primero el Dominio.'); return; }

  // El sitio valida el valor que está en el campo. Lo normalizamos para
  // que el DV calculado corresponda exactamente al dominio que se envía.
  $dom.val(dominio);

  let dv;
  try {
    if (typeof patente === 'undefined') throw new Error('patente no disponible');

    // Nunca llamar a getDv sin validar: con una letra fuera de la tabla
    // (p. ej. Ñ) y una racha de 9+ dígitos, el original puede quedar en
    // un bucle infinito.
    const check = patente.valido(dominio);
    if (check !== true) { alert(check); return; }

    dv = patente.getDv(dominio);
  } catch (e) {
    alert('No se pudo calcular: ' + e.message);
    return;
  }

  // Muestra el campo "Dígito verificador" (el handler escucha 'change')
  const $chk = $('#chkDigitoVerificador');
  if (!$chk.is(':checked')) $chk.prop('checked', true).trigger('change');

  $('#fldDigitoVerificador').val(String(dv));
  console.log('%c' + dominio + ' -> DV ' + dv, 'color:#2ebc98;font-weight:bold');
})();

/* ------------------------------------------------------------------
 * CALCULAR_DOMINIO_ABAJO - copia y pega SOLO esta línea para otra patente:
 *
 *   (function($){var d=($('#fldDominio').val()||'').trim().toUpperCase();if(!d)return alert('Cargá primero el Dominio.');$('#fldDominio').val(d);if(typeof patente==='undefined')return alert('patente no disponible');var ok=patente.valido(d);if(ok!==true)return alert(ok);var c=$('#chkDigitoVerificador');if(!c.is(':checked'))c.prop('checked',true).trigger('change');var dv=patente.getDv(d);$('#fldDigitoVerificador').val(String(dv));console.log(d+' -> '+dv);})(jQuery);
 * ------------------------------------------------------------------ */
