/**
 * Auxiliar de mantenimiento: incrusta los vectores dorados en test-paridad.js.
 *
 *   node tools/embed-golden.js restore  -> vuelve el marcador a `{}`
 *   node tools/embed-golden.js embed    -> lee golden.json y lo incrusta
 *
 * Se usa golden.json generado con:  node test-paridad.js --dump-golden > golden.json
 * (redirigir con `cmd /c` para que salga UTF-8 sin BOM ni UTF-16).
 */
const fs = require('fs');
const path = require('path');

const target = path.join(__dirname, '..', 'test-paridad.js');
const mode = process.argv[2];
let src = fs.readFileSync(target, 'utf8');

// normalizar cualquier residuo de volcados anteriores (BOM/UTF-16/reemplazos)
const lineas = src.split('\n');
const idx = lineas.findIndex(l => l.startsWith('const GOLDEN'));
if (idx < 0) {
	console.error('No se encontro la linea const GOLDEN ...');
	process.exit(1);
}

if (mode === 'restore') {
	lineas[idx] = 'const GOLDEN = {};';
	fs.writeFileSync(target, lineas.join('\n'), 'utf8');
	console.log('marcador restaurado');
	process.exit(0);
}

if (mode === 'embed') {
	const gpath = path.join(__dirname, '..', 'golden.json');
	let raw = fs.readFileSync(gpath, 'utf8');
	if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);
	raw = raw.trim();
	const obj = JSON.parse(raw); // valida
	lineas[idx] = 'const GOLDEN = ' + JSON.stringify(obj) + ';';
	fs.writeFileSync(target, lineas.join('\n'), 'utf8');
	console.log('incrustadas ' + Object.keys(obj).length + ' entradas; archivo: '
		+ fs.statSync(target).size + ' bytes');
	process.exit(0);
}

console.error('Uso: node tools/embed-golden.js restore|embed');
process.exit(2);
