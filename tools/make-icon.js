/**
 * Genera iconos/dv-caba.ico sin dependencias externas.
 *  - Renderiza un master RGBA de 768x768 (divisible por 16/24/32/48/64/128/256)
 *  - Baja resolucion con promedio de cajas (antialiasing)
 *  - Empaqueta PNGs dentro de un .ico valido (Vista+)
 *
 * Diseno: cuadrado redondeado con degradado teal (color de AGIP) + monograma
 * "DV" blanco. Para 16/24/32 px usa un check (legible en tamano minimo).
 *
 *   node tools/make-icon.js
 */
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const M = 768;
const SIZES = [16, 24, 32, 48, 64, 128, 256];

// ---------------------------------------------------------------- primitivas
function clamp(v, a, b) { return v < a ? a : v > b ? b : v; }

function sdRoundRect(px, py, cx, cy, hw, hh, r) {
	const qx = Math.abs(px - cx) - (hw - r);
	const qy = Math.abs(py - cy) - (hh - r);
	const ax = Math.max(qx, 0), ay = Math.max(qy, 0);
	return Math.hypot(ax, ay) + Math.min(Math.max(qx, qy), 0) - r;
}

function distToSeg(px, py, x1, y1, x2, y2) {
	const vx = x2 - x1, vy = y2 - y1;
	const wx = px - x1, wy = py - y1;
	const L2 = vx * vx + vy * vy;
	let t = L2 === 0 ? 0 : (wx * vx + wy * vy) / L2;
	t = clamp(t, 0, 1);
	const dx = wx - t * vx, dy = wy - t * vy;
	return Math.hypot(dx, dy);
}

// cobertura de un rectangulo (AA exacto por solape de celda)
function rectCov(px, py, x0, y0, x1, y1) {
	const ox = Math.min(x1, px + 1) - Math.max(x0, px);
	const oy = Math.min(y1, py + 1) - Math.max(y0, py);
	return ox <= 0 || oy <= 0 ? 0 : clamp(ox, 0, 1) * clamp(oy, 0, 1);
}

// ------------------------------------------------------------------- dibujo
const FONT = {
	D: ['11110', '10001', '10001', '10001', '10001', '10001', '11110'],
};

function lerpColor(t, a, b) {
	return [
		Math.round(a[0] + (b[0] - a[0]) * t),
		Math.round(a[1] + (b[1] - a[1]) * t),
		Math.round(a[2] + (b[2] - a[2]) * t),
	];
}

function render(useMonogram) {
	const buf = new Uint8Array(M * M * 4);
	const S = M;
	const pad = S * 0.055;
	const radius = S * 0.215;
	const cx = S / 2, cy = S / 2;
	const hw = S / 2 - pad, hh = S / 2 - pad;

	const top = [53, 214, 166];      // #35D6A6
	const bottom = [18, 153, 120];   // #129978
	const strokeW = S * 0.012;

	// geometria del monograma / check
	let marks = [];
	if (useMonogram) {
		const u = S * 0.054;                // unidad del font 5x7
		const gap = u * 0.75;               // separacion entre letras
		const letterW = 5 * u;
		const totalH = 7 * u;
		const totalW = letterW + gap + letterW;
		const x0 = (S - totalW) / 2;
		const y0 = (S - totalH) / 2;
		const dil = u * 0.15;               // "negro tipografico"

		// D: anillo (bitmap 5x7), bordes rectos tipograficos
		const g = FONT.D;
		for (let r = 0; r < 7; r++)
			for (let c = 0; c < 5; c++)
				if (g[r][c] === '1') {
					const bx = x0 + c * u, by = y0 + r * u;
					marks.push({ type: 'rect', x0: bx - dil, y0: by - dil, x1: bx + u + dil, y1: by + u + dil });
				}

		// V: dos trazos vectoriales con punta redonda (misma familia que el check)
		const vx0 = x0 + letterW + gap;
		const w = u * 1.3;
		marks.push(
			{ type: 'seg', a: [vx0 + 0.35 * u, y0 + 0.55 * u], b: [vx0 + 2.5 * u, y0 + 6.55 * u], w: w },
			{ type: 'seg', a: [vx0 + 4.65 * u, y0 + 0.55 * u], b: [vx0 + 2.5 * u, y0 + 6.55 * u], w: w }
		);
	} else {
		// check grueso, legible a 16 px
		const p = [
			[S * 0.26, S * 0.52],
			[S * 0.43, S * 0.70],
			[S * 0.75, S * 0.32],
		];
		marks = [
			{ type: 'seg', a: p[0], b: p[1], w: S * 0.115 },
			{ type: 'seg', a: p[1], b: p[2], w: S * 0.115 },
		];
	}

	for (let y = 0; y < S; y++) {
		for (let x = 0; x < S; x++) {
			const px = x + 0.5, py = y + 0.5;
			const d = sdRoundRect(px, py, cx, cy, hw, hh, radius);
			const cover = clamp(0.5 - d, 0, 1);
			if (cover <= 0) continue;

			// fondo con degradado vertical
			const t = clamp((py - (cy - hh)) / (2 * hh), 0, 1);
			let col = lerpColor(t, top, bottom);

			// borde interior claro
			const inner = clamp(0.5 - (d + strokeW), 0, 1);
			if (inner > 0) {
				col = [
					Math.round(col[0] + (255 - col[0]) * 0.42 * inner),
					Math.round(col[1] + (255 - col[1]) * 0.42 * inner),
					Math.round(col[2] + (255 - col[2]) * 0.42 * inner),
				];
			}

			// marca blanca
			let white = 0;
			for (const m of marks) {
				let c = 0;
				if (m.type === 'rect') c = rectCov(x, y, m.x0, m.y0, m.x1, m.y1);
				else {
					const dd = distToSeg(px, py, m.a[0], m.a[1], m.b[0], m.b[1]);
					c = clamp(0.5 - (dd - m.w / 2), 0, 1);
				}
				white = Math.max(white, c);
			}
			if (white > 0) {
				col = [
					Math.round(col[0] + (255 - col[0]) * white),
					Math.round(col[1] + (255 - col[1]) * white),
					Math.round(col[2] + (255 - col[2]) * white),
				];
			}

			const i = (y * S + x) * 4;
			buf[i] = col[0];
			buf[i + 1] = col[1];
			buf[i + 2] = col[2];
			buf[i + 3] = Math.round(255 * cover);
		}
	}
	return buf;
}

function downsample(src, size) {
	const out = new Uint8Array(size * size * 4);
	const k = M / size;
	for (let y = 0; y < size; y++) {
		for (let x = 0; x < size; x++) {
			let r = 0, g = 0, b = 0, a = 0;
			for (let j = 0; j < k; j++) {
				for (let i = 0; i < k; i++) {
					const o = ((y * k + j) * M + (x * k + i)) * 4;
					const al = src[o + 3];
					r += src[o] * al; g += src[o + 1] * al; b += src[o + 2] * al; a += al;
				}
			}
			const n = k * k, ai = a / n;
			const o = (y * size + x) * 4;
			out[o] = a ? Math.round(r / a) : 0;
			out[o + 1] = a ? Math.round(g / a) : 0;
			out[o + 2] = a ? Math.round(b / a) : 0;
			out[o + 3] = Math.round(255 * (ai / 255));
		}
	}
	return out;
}

// ---------------------------------------------------------------------- PNG
const CRC_TABLE = (() => {
	const t = new Uint32Array(256);
	for (let n = 0; n < 256; n++) {
		let c = n;
		for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
		t[n] = c >>> 0;
	}
	return t;
})();
function crc32(buf) {
	let c = 0xFFFFFFFF;
	for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xFF] ^ (c >>> 8);
	return (c ^ 0xFFFFFFFF) >>> 0;
}
function chunk(type, data) {
	const len = Buffer.alloc(4); len.writeUInt32BE(data.length, 0);
	const td = Buffer.concat([Buffer.from(type, 'ascii'), data]);
	const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td), 0);
	return Buffer.concat([len, td, crc]);
}
function encodePNG(size, rgba, height) {
	const w = size, h = height === undefined ? size : height;
	const raw = Buffer.alloc(h * (1 + w * 4));
	for (let y = 0; y < h; y++) {
		raw[y * (1 + w * 4)] = 0;
		Buffer.from(rgba.buffer, rgba.byteOffset + y * w * 4, w * 4)
			.copy(raw, y * (1 + w * 4) + 1);
	}
	const ihdr = Buffer.alloc(13);
	ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
	ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
	return Buffer.concat([
		Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
		chunk('IHDR', ihdr),
		chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
		chunk('IEND', Buffer.alloc(0)),
	]);
}

// ----------------------------------------------------------------------- ICO
function buildICO(images) {
	const count = images.length;
	const header = Buffer.alloc(6);
	header.writeUInt16LE(0, 0); header.writeUInt16LE(1, 2); header.writeUInt16LE(count, 4);
	let offset = 6 + count * 16;
	const entries = [];
	for (const img of images) {
		const e = Buffer.alloc(16);
		e[0] = img.size >= 256 ? 0 : img.size;
		e[1] = img.size >= 256 ? 0 : img.size;
		e[2] = 0; e[3] = 0;
		e.writeUInt16LE(1, 4);      // planes
		e.writeUInt16LE(32, 6);     // bit count
		e.writeUInt32LE(img.png.length, 8);
		e.writeUInt32LE(offset, 12);
		offset += img.png.length;
		entries.push(e);
	}
	return Buffer.concat([header, ...entries, ...images.map(i => i.png)]);
}

// ----------------------------------------------------------------------- run
const outDir = path.join(__dirname, '..', 'iconos');
fs.mkdirSync(outDir, { recursive: true });

const images = [];
for (const size of SIZES) {
	const master = render(size >= 48);            // monograma >=48, check <=32
	const rgba = size === M ? master : downsample(master, size);
	const png = encodePNG(size, rgba);
	images.push({ size, png });
	fs.writeFileSync(path.join(outDir, `preview-${size}.png`), png);
}

const ico = buildICO(images);
fs.writeFileSync(path.join(outDir, 'dv-caba.ico'), ico);

// acento horizontal teal para la GUI (barra de 4-12 px estirada en la pagina)
{
	const W = 96, H = 12;
	const a = [46, 188, 152], b = [15, 118, 110];   // #2EBC98 -> #0F766E
	const rgba = new Uint8Array(W * H * 4);
	for (let y = 0; y < H; y++) {
		for (let x = 0; x < W; x++) {
			const t = x / (W - 1);
			const i = (y * W + x) * 4;
			rgba[i] = Math.round(a[0] + (b[0] - a[0]) * t);
			rgba[i + 1] = Math.round(a[1] + (b[1] - a[1]) * t);
			rgba[i + 2] = Math.round(a[2] + (b[2] - a[2]) * t);
			rgba[i + 3] = 255;
		}
	}
	const png = encodePNG(W, rgba, H);
	fs.writeFileSync(path.join(outDir, 'accent-teal.png'), png);
	console.log('PNG: accent-teal.png (' + png.length + ' bytes)');
}

console.log('ICO: ' + path.join(outDir, 'dv-caba.ico') + ' (' + ico.length + ' bytes)');
images.forEach(i => console.log('  ' + String(i.size).padStart(3) + 'px  ' + i.png.length + ' bytes  sha256=' +
	require('crypto').createHash('sha256').update(i.png).digest('hex').slice(0, 16)));
