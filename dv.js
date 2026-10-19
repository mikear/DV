/**
 * Dígito verificador de patentes CABA (AGIP) - https://lb.agip.gob.ar/ConsultaPat/
 *
 * Implementación 1:1 de `patente.getDv()` de
 * https://lb.agip.gob.ar/libFe/js/patente.js
 * (incluye sus particularidades: replace de 1ª ocurrencia, regex sin anclar, etc.)
 *
 * Uso:  node dv.js AB123CD
 *       node dv.js AB123CD A1234567 123ABC
 */

var patente = {
	patronPatAutoVieja : /^[A-Z]{1}\d{7}$/,
	patronPatAutoNueva : /^[A-Z]{3}\d{3}$/,
	patronPatMotoNueva : /^\d{3}[A-Z]{3}$/,
	patronPatAutoMercosur : /^[A-Z]{2}\d{3}[A-Z]{2}$/,
	patronPatMotoMercosur : /^[A-Z]{1}\d{3}[A-Z]{3}$/,

	valido : function(patente, dv) {
		var patAux = patente.toUpperCase();
		if (patAux == '') {
			return 'Debe especificar el dominio a consultar.';
		}
		if (!this.patronPatAutoVieja.test(patAux) && !this.patronPatAutoNueva.test(patAux)
			&& !this.patronPatMotoNueva.test(patAux) && !this.patronPatAutoMercosur.test(patAux)
			&& !this.patronPatMotoMercosur.test(patAux)) {
			return 'El dominio especificado no tiene un formato válido.';
		}
		if (dv != undefined) {
			return this.validoDv(patente, dv);
		}
		return true;
	},

	validoDv : function(patente, dv) {
		try {
			if (dv == '') {
				return 'Debe especificar el dígito verificador del dominio';
			}
			if (this.getDv(patente) != parseInt(dv)) {
				return 'El dígito verificador especificado no tiene un formato válido';
			}
		} catch (e) {
			return e.message;
		}
		return true;
	},

	getDv : function(patente) {
		var key = '';
		var patAux = patente.toUpperCase();
		var a = 0;
		var b = 0;
		var x;
		var digi1;
		var digi2;
		var letrasValidas = {};
		var patronNumeroFinal = /\d{9,11}/;

		letrasValidas['A'] = '14';
		letrasValidas['B'] = '01';
		letrasValidas['C'] = '00';
		letrasValidas['D'] = '16';
		letrasValidas['E'] = '05';
		letrasValidas['F'] = '20';
		letrasValidas['G'] = '19';
		letrasValidas['H'] = '09';
		letrasValidas['I'] = '24';
		letrasValidas['J'] = '07';
		letrasValidas['K'] = '21';
		letrasValidas['L'] = '08';
		letrasValidas['M'] = '04';
		letrasValidas['N'] = '13';
		letrasValidas['O'] = '25';
		letrasValidas['P'] = '22';
		letrasValidas['Q'] = '18';
		letrasValidas['R'] = '10';
		letrasValidas['S'] = '02';
		letrasValidas['T'] = '06';
		letrasValidas['U'] = '12';
		letrasValidas['V'] = '23';
		letrasValidas['W'] = '11';
		letrasValidas['X'] = '03';
		letrasValidas['Y'] = '15';
		letrasValidas['Z'] = '17';
		letrasValidas[' '] = '60';

		if (this.patronPatAutoVieja.test(patAux)) {
			for (key in letrasValidas) {
				patAux = patAux.replace(key, "00");
			}
		} else {
			for (key in letrasValidas) {
				patAux = patAux.replace(key, letrasValidas[key]);
				patAux = patAux.replace(key, letrasValidas[key]);
				patAux = patAux.replace(key, letrasValidas[key]);
				patAux = patAux.replace(key, letrasValidas[key]);
			}
		}

		if (!patronNumeroFinal.test(patAux)) {
			throw Error('No es válida la patente ingresada.');
		}

		for (x = 0; x < patAux.length; x++) {
			if (x % 2 == 0)
				a += parseInt(patAux.charAt(x));
			else
				b += parseInt(patAux.charAt(x));
		}

		digi1 = new String(a);
		while (digi1.length > 1) {
			a = 0;
			for (x = 0; x < digi1.length; x++) {
				a += parseInt(digi1.charAt(x));
			}
			digi1 = new String(a);
		}

		digi2 = new String(b);
		while (digi2.length > 1) {
			b = 0;
			for (x = 0; x < digi2.length; x++) {
				b += parseInt(digi2.charAt(x));
			}
			digi2 = new String(b);
		}

		return parseInt(a + '' + b);
	},

	/**
	 * Calcula el DV siguiendo el MISMO flujo que el sitio:
	 * primero valida el formato (valido) y recién después llama a getDv.
	 *
	 * Motivo: el original puede quedar en bucle infinito si getDv recibe un
	 * string con letras sobrantes (más de 4 repetidas de la misma) y una
	 * racha de >=9 dígitos: parseInt('A') = NaN y el while de raíz digital
	 * nunca termina. En el sitio eso es inalcanzable porque validarCampos
	 * llama a valido() antes que validoDv().
	 */
	calcularDV : function(dominio) {
		var ok = this.valido(dominio);
		if (ok !== true) {
			throw new Error(ok);
		}
		return this.getDv(dominio);
	}
};

module.exports = patente;

if (require.main === module) {
	var args = process.argv.slice(2);
	if (args.length === 0) {
		console.error('Uso: node dv.js <PATENTE> [PATENTE...]');
		process.exit(1);
	}
	args.forEach(function(p) {
		var formato = patente.valido(p);
		var dv = null;
		var err = null;
		if (formato !== true) {
			err = formato;                       // mensaje de error del sitio
		} else {
			try {
				dv = patente.calcularDV(p);
			} catch (e) {
				err = e.message;
			}
		}
		console.log(
			(p + '            ').substring(0, 12)
			+ ' DV: ' + (dv !== null ? dv : '---')
			+ '   [' + (err === null ? 'formato OK' : err) + ']'
		);
	});
}
