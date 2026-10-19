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

  // Muestra el campo "Dígito verificador" (el handler escucha 'change')
  const $chk = $('#chkDigitoVerificador');
  if (!$chk.is(':checked')) $chk.prop('checked', true).trigger('change');

  let dv;
  try {
    dv = patente.getDv(dominio);           // función original del sitio
  } catch (e) {
    alert('No se pudo calcular: ' + e.message);
    return;
  }

  $('#fldDigitoVerificador').val(String(dv));
  console.log('%c' + dominio + ' -> DV ' + dv, 'color:#2ebc98;font-weight:bold');
})();

/* ------------------------------------------------------------------
 * CALCULAR_DOMINIO_ABAJO - copia y pega SOLO esta línea para otra patente:
 *
 *   (function(d){var c=jQuery('#chkDigitoVerificador');if(!c.is(':checked'))c.prop('checked',true).trigger('change');jQuery('#fldDigitoVerificador').val(String(patente.getDv(d)));console.log(d+' -> '+patente.getDv(d));})(jQuery('#fldDominio').val().trim().toUpperCase());
 * ------------------------------------------------------------------ */
