/**
 * Test de paridad: nuestra implementación (dv.js) vs. el patente.js REAL
 * exportado por REA desde el navegador (bytes servidos por AGIP).
 *
 *   node test-paridad.js                -> corre la batería completa
 *   node test-paridad.js --dump-golden  -> imprime los valores esperados
 *                                          (requiere el export de AGIP)
 *
 * El paquete público NO incluye el export de AGIP (es código de terceros).
 * En ese caso el test corre igual, comparando contra los vectores dorados
 * congelados en GOLDEN, que fueron generados con este mismo comando y
 * verificados contra el original en el entorno privado de ingeniería inversa.
 */
const fs = require('fs');
const path = require('path');
const vm = require('vm');
const crypto = require('crypto');
const mine = require('./dv.js');

// ---- localizar el original exportado por REA (opcional) --------------------
function walk(dir, out = []) {
	for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
		const p = path.join(dir, e.name);
		if (e.isDirectory()) walk(p, out);
		else out.push(p);
	}
	return out;
}
const root = path.join(__dirname, 'web-scripts', 'files');
let originalPath = null;
let orig = null;
try {
	originalPath = walk(root).find(p => p.replace(/\\/g, '/').endsWith('/libFe/js/patente.js'));
} catch (e) {
	originalPath = null;
}
if (originalPath) {
	const originalCode = fs.readFileSync(originalPath, 'utf8');
	const ctx = { };
	vm.createContext(ctx);
	vm.runInContext(originalCode + '\n;this.__patente = patente;', ctx);
	orig = ctx.__patente;
}

// ---- batería de casos ------------------------------------------------------
function rng(seed) { // LCG determinista
	let s = seed >>> 0;
	return () => (s = (s * 1664525 + 1013904223) >>> 0) / 4294967296;
}
const LETRAS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const DIG = '0123456789';

function gen(patron, r) {
	const L = () => LETRAS[Math.floor(r() * 26)];
	const D = () => DIG[Math.floor(r() * 10)];
	switch (patron) {
		case 'vieja':    return L() + D() + D() + D() + D() + D() + D() + D();
		case 'nueva':    return L() + L() + L() + D() + D() + D();
		case 'moto':     return D() + D() + D() + L() + L() + L();
		case 'mercosur': return L() + L() + D() + D() + D() + L() + L();
		case 'motoM':    return L() + D() + D() + D() + L() + L() + L();
	}
}

const casos = [
	// --- borde manual ---
	'ZZ0000ZZ',            // formato invalido (8 chars, no es Mercosur)
	// --- manuales / borde ---
	'A1234567', 'Z9876543', 'ABC123', 'AAA999', 'XYZ000',
	'123ABC', '999ZZZ', 'QQ999QQ', 'AB123CD', 'ZZ999AA',
	'A123BCD', 'Z012BCD', 'CCC000', 'A0000000', '000AAA',
	'AAA111', 'QQQ999', 'A1A1A1A1', // formato invalido -> debe fallar igual
	'Ñ1234567', 'A12345678', 'A12345', 'QQ999QQ ', 'qq999qq',
	// --- generados ---
];
const r = rng(20261019);
for (let i = 0; i < 400; i++) {
	casos.push(gen(['vieja', 'nueva', 'moto', 'mercosur', 'motoM'][i % 5], r));
}
// repetidas de letra (para ejercitar el replace multiple)
casos.push('AAAA999', 'BBBB111', 'CCCC222', 'ABCABC', 'LLLL123', 'ZZZZ000', 'AAAAAAA1', 'ABABAB');

// deduplicar conservando el orden
const vistos = new Set();
const suite = casos.filter(p => (vistos.has(p) ? false : (vistos.add(p), true)));

// ---- vectores dorados (generados con --dump-golden) ------------------------
const GOLDEN = {"ZZ0000ZZ":{"ok":true,"v":41,"valido":"El dominio especificado no tiene un formato válido."},"A1234567":{"ok":true,"v":73,"valido":"true"},"Z9876543":{"ok":true,"v":69,"valido":"true"},"ABC123":{"ok":true,"v":57,"valido":"true"},"AAA999":{"ok":true,"v":33,"valido":"true"},"XYZ000":{"ok":true,"v":26,"valido":"true"},"123ABC":{"ok":true,"v":93,"valido":"true"},"999ZZZ":{"ok":true,"v":33,"valido":"true"},"QQ999QQ":{"ok":true,"v":99,"valido":"true"},"AB123CD":{"ok":true,"v":28,"valido":"true"},"ZZ999AA":{"ok":true,"v":17,"valido":"true"},"A123BCD":{"ok":true,"v":37,"valido":"true"},"Z012BCD":{"ok":true,"v":19,"valido":"true"},"CCC000":{"ok":true,"v":0,"valido":"true"},"A0000000":{"ok":true,"v":0,"valido":"true"},"000AAA":{"ok":true,"v":33,"valido":"true"},"AAA111":{"ok":true,"v":54,"valido":"true"},"QQQ999":{"ok":true,"v":36,"valido":"true"},"A1A1A1A1":{"ok":true,"v":33,"valido":"El dominio especificado no tiene un formato válido."},"Ñ1234567":{"ok":false,"v":"No es válida la patente ingresada.","valido":"El dominio especificado no tiene un formato válido."},"A12345678":{"ok":true,"v":86,"valido":"El dominio especificado no tiene un formato válido."},"A12345":{"ok":false,"v":"No es válida la patente ingresada.","valido":"El dominio especificado no tiene un formato válido."},"QQ999QQ ":{"ok":true,"v":96,"valido":"El dominio especificado no tiene un formato válido."},"qq999qq":{"ok":true,"v":99,"valido":"true"},"L9198782":{"ok":true,"v":98,"valido":"true"},"MPU178":{"ok":true,"v":36,"valido":"true"},"171CUV":{"ok":true,"v":71,"valido":"true"},"BH714CQ":{"ok":true,"v":13,"valido":"true"},"J133CQJ":{"ok":true,"v":12,"valido":"true"},"T5535691":{"ok":true,"v":61,"valido":"true"},"VXW333":{"ok":true,"v":91,"valido":"true"},"533GGF":{"ok":true,"v":87,"valido":"true"},"GL113GJ":{"ok":true,"v":31,"valido":"true"},"A460HWI":{"ok":true,"v":14,"valido":"true"},"U7119499":{"ok":true,"v":31,"valido":"true"},"PPB553":{"ok":true,"v":31,"valido":"true"},"892YUZ":{"ok":true,"v":63,"valido":"true"},"JT088NF":{"ok":true,"v":26,"valido":"true"},"Z664ASQ":{"ok":true,"v":76,"valido":"true"},"N1763645":{"ok":true,"v":95,"valido":"true"},"ZYD349":{"ok":true,"v":64,"valido":"true"},"677JXL":{"ok":true,"v":47,"valido":"true"},"ET854AI":{"ok":true,"v":21,"valido":"true"},"N121HJV":{"ok":true,"v":47,"valido":"true"},"V3563052":{"ok":true,"v":24,"valido":"true"},"HRC914":{"ok":true,"v":51,"valido":"true"},"815MTC":{"ok":true,"v":51,"valido":"true"},"OT614DR":{"ok":true,"v":95,"valido":"true"},"I036PWY":{"ok":true,"v":72,"valido":"true"},"K6607948":{"ok":true,"v":58,"valido":"true"},"KLK869":{"ok":true,"v":37,"valido":"true"},"379BEO":{"ok":true,"v":59,"valido":"true"},"VJ183MC":{"ok":true,"v":19,"valido":"true"},"V287IAW":{"ok":true,"v":26,"valido":"true"},"K0099706":{"ok":true,"v":49,"valido":"true"},"WSW448":{"ok":true,"v":58,"valido":"true"},"416JLZ":{"ok":true,"v":52,"valido":"true"},"GG351EF":{"ok":true,"v":27,"valido":"true"},"W509SSQ":{"ok":true,"v":92,"valido":"true"},"P6793607":{"ok":true,"v":11,"valido":"true"},"LDJ811":{"ok":true,"v":14,"valido":"true"},"147BJW":{"ok":true,"v":85,"valido":"true"},"UD916DQ":{"ok":true,"v":42,"valido":"true"},"M084JCD":{"ok":true,"v":84,"valido":"true"},"J6523117":{"ok":true,"v":79,"valido":"true"},"TPG058":{"ok":true,"v":24,"valido":"true"},"397NOS":{"ok":true,"v":23,"valido":"true"},"AY704LJ":{"ok":true,"v":19,"valido":"true"},"D858UIU":{"ok":true,"v":76,"valido":"true"},"Q8261945":{"ok":true,"v":17,"valido":"true"},"HHY877":{"ok":true,"v":73,"valido":"true"},"313MED":{"ok":true,"v":32,"valido":"true"},"XZ644VP":{"ok":true,"v":79,"valido":"true"},"L655QPZ":{"ok":true,"v":18,"valido":"true"},"C2244823":{"ok":true,"v":88,"valido":"true"},"CES988":{"ok":true,"v":86,"valido":"true"},"738THK":{"ok":true,"v":45,"valido":"true"},"EQ137EZ":{"ok":true,"v":38,"valido":"true"},"B960PEK":{"ok":true,"v":82,"valido":"true"},"V9112007":{"ok":true,"v":83,"valido":"true"},"SMO701":{"ok":true,"v":12,"valido":"true"},"603TDW":{"ok":true,"v":42,"valido":"true"},"MN977GX":{"ok":true,"v":26,"valido":"true"},"H657XZB":{"ok":true,"v":66,"valido":"true"},"W8953289":{"ok":true,"v":62,"valido":"true"},"PGM209":{"ok":true,"v":56,"valido":"true"},"658OAF":{"ok":true,"v":51,"valido":"true"},"HC765FO":{"ok":true,"v":81,"valido":"true"},"O989PHA":{"ok":true,"v":87,"valido":"true"},"D1036378":{"ok":true,"v":64,"valido":"true"},"CXO482":{"ok":true,"v":87,"valido":"true"},"775RDA":{"ok":true,"v":41,"valido":"true"},"WK821WB":{"ok":true,"v":55,"valido":"true"},"Z222GBP":{"ok":true,"v":83,"valido":"true"},"Q5424061":{"ok":true,"v":85,"valido":"true"},"LDK372":{"ok":true,"v":84,"valido":"true"},"154GBZ":{"ok":true,"v":47,"valido":"true"},"JL271FE":{"ok":true,"v":86,"valido":"true"},"W982TZD":{"ok":true,"v":42,"valido":"true"},"Y7889809":{"ok":true,"v":58,"valido":"true"},"EIN424":{"ok":true,"v":25,"valido":"true"},"725MIT":{"ok":true,"v":84,"valido":"true"},"XA293DN":{"ok":true,"v":69,"valido":"true"},"T574MNJ":{"ok":true,"v":55,"valido":"true"},"Y9448197":{"ok":true,"v":33,"valido":"true"},"IGR576":{"ok":true,"v":62,"valido":"true"},"257LRL":{"ok":true,"v":76,"valido":"true"},"NV384OG":{"ok":true,"v":68,"valido":"true"},"A870IFN":{"ok":true,"v":77,"valido":"true"},"M2856243":{"ok":true,"v":39,"valido":"true"},"NEU862":{"ok":true,"v":37,"valido":"true"},"280KUE":{"ok":true,"v":12,"valido":"true"},"VX547HP":{"ok":true,"v":73,"valido":"true"},"Z119SFJ":{"ok":true,"v":21,"valido":"true"},"M1224928":{"ok":true,"v":28,"valido":"true"},"QWT235":{"ok":true,"v":99,"valido":"true"},"410LOB":{"ok":true,"v":93,"valido":"true"},"MJ952DV":{"ok":true,"v":21,"valido":"true"},"C286QTN":{"ok":true,"v":71,"valido":"true"},"T4015450":{"ok":true,"v":91,"valido":"true"},"GSC296":{"ok":true,"v":92,"valido":"true"},"254DNS":{"ok":true,"v":87,"valido":"true"},"ZY107ST":{"ok":true,"v":93,"valido":"true"},"K578MHJ":{"ok":true,"v":88,"valido":"true"},"D4500432":{"ok":true,"v":18,"valido":"true"},"GPO508":{"ok":true,"v":97,"valido":"true"},"308QLB":{"ok":true,"v":11,"valido":"true"},"TO227AQ":{"ok":true,"v":56,"valido":"true"},"Y731RXZ":{"ok":true,"v":11,"valido":"true"},"T0487035":{"ok":true,"v":45,"valido":"true"},"COL125":{"ok":true,"v":86,"valido":"true"},"990PHD":{"ok":true,"v":83,"valido":"true"},"CG543LO":{"ok":true,"v":46,"valido":"true"},"S496RTC":{"ok":true,"v":73,"valido":"true"},"D1985317":{"ok":true,"v":16,"valido":"true"},"BJF651":{"ok":true,"v":94,"valido":"true"},"062JSB":{"ok":true,"v":36,"valido":"true"},"TM012RT":{"ok":true,"v":83,"valido":"true"},"U907DGD":{"ok":true,"v":25,"valido":"true"},"V8793361":{"ok":true,"v":37,"valido":"true"},"LGN194":{"ok":true,"v":72,"valido":"true"},"760IZG":{"ok":true,"v":91,"valido":"true"},"US663ZM":{"ok":true,"v":32,"valido":"true"},"C022IXS":{"ok":true,"v":24,"valido":"true"},"P9797311":{"ok":true,"v":46,"valido":"true"},"ASN503":{"ok":true,"v":19,"valido":"true"},"734YOO":{"ok":true,"v":88,"valido":"true"},"UO802SL":{"ok":true,"v":57,"valido":"true"},"A922SLQ":{"ok":true,"v":37,"valido":"true"},"R3116322":{"ok":true,"v":99,"valido":"true"},"WUD587":{"ok":true,"v":68,"valido":"true"},"981YJN":{"ok":true,"v":71,"valido":"true"},"TW429BV":{"ok":true,"v":92,"valido":"true"},"F662UZS":{"ok":true,"v":38,"valido":"true"},"F3288553":{"ok":true,"v":16,"valido":"true"},"JJB924":{"ok":true,"v":48,"valido":"true"},"271FUZ":{"ok":true,"v":32,"valido":"true"},"KW037PE":{"ok":true,"v":87,"valido":"true"},"S714EOZ":{"ok":true,"v":16,"valido":"true"},"O5352457":{"ok":true,"v":31,"valido":"true"},"UPQ218":{"ok":true,"v":54,"valido":"true"},"057EPD":{"ok":true,"v":28,"valido":"true"},"JD948TH":{"ok":true,"v":68,"valido":"true"},"O766LZJ":{"ok":true,"v":13,"valido":"true"},"U2270680":{"ok":true,"v":61,"valido":"true"},"BAH650":{"ok":true,"v":71,"valido":"true"},"418MYY":{"ok":true,"v":83,"valido":"true"},"DZ901EI":{"ok":true,"v":36,"valido":"true"},"T862LFP":{"ok":true,"v":27,"valido":"true"},"W1476137":{"ok":true,"v":74,"valido":"true"},"RJK477":{"ok":true,"v":56,"valido":"true"},"171MPB":{"ok":true,"v":99,"valido":"true"},"PL013XP":{"ok":true,"v":14,"valido":"true"},"T960FAV":{"ok":true,"v":78,"valido":"true"},"X6318321":{"ok":true,"v":24,"valido":"true"},"FYQ667":{"ok":true,"v":81,"valido":"true"},"788MGG":{"ok":true,"v":11,"valido":"true"},"MW011KW":{"ok":true,"v":49,"valido":"true"},"D626EDZ":{"ok":true,"v":41,"valido":"true"},"J9697640":{"ok":true,"v":68,"valido":"true"},"FRS573":{"ok":true,"v":29,"valido":"true"},"191HUT":{"ok":true,"v":11,"valido":"true"},"FP869WV":{"ok":true,"v":72,"valido":"true"},"O481CAV":{"ok":true,"v":57,"valido":"true"},"T9856765":{"ok":true,"v":82,"valido":"true"},"XEN492":{"ok":true,"v":72,"valido":"true"},"898LQV":{"ok":true,"v":83,"valido":"true"},"VV085PY":{"ok":true,"v":78,"valido":"true"},"X530SOU":{"ok":true,"v":59,"valido":"true"},"X2330290":{"ok":true,"v":73,"valido":"true"},"RDF781":{"ok":true,"v":35,"valido":"true"},"379IJV":{"ok":true,"v":82,"valido":"true"},"HI843LF":{"ok":true,"v":31,"valido":"true"},"X803YDQ":{"ok":true,"v":36,"valido":"true"},"V6849523":{"ok":true,"v":91,"valido":"true"},"MWY254":{"ok":true,"v":86,"valido":"true"},"435SPF":{"ok":true,"v":47,"valido":"true"},"EW096WF":{"ok":true,"v":89,"valido":"true"},"Q026ROU":{"ok":true,"v":55,"valido":"true"},"J0026669":{"ok":true,"v":83,"valido":"true"},"PFN658":{"ok":true,"v":11,"valido":"true"},"412SYG":{"ok":true,"v":43,"valido":"true"},"VH727YK":{"ok":true,"v":48,"valido":"true"},"L307GBW":{"ok":true,"v":31,"valido":"true"},"O7440083":{"ok":true,"v":53,"valido":"true"},"CQD511":{"ok":true,"v":86,"valido":"true"},"489QUI":{"ok":true,"v":93,"valido":"true"},"UX496QX":{"ok":true,"v":46,"valido":"true"},"A794XDE":{"ok":true,"v":85,"valido":"true"},"S7533765":{"ok":true,"v":45,"valido":"true"},"ECO859":{"ok":true,"v":16,"valido":"true"},"172KQP":{"ok":true,"v":53,"valido":"true"},"AA899VT":{"ok":true,"v":11,"valido":"true"},"G195FTT":{"ok":true,"v":12,"valido":"true"},"K8173036":{"ok":true,"v":37,"valido":"true"},"SHX967":{"ok":true,"v":72,"valido":"true"},"104ASE":{"ok":true,"v":71,"valido":"true"},"WQ839TX":{"ok":true,"v":13,"valido":"true"},"X822UIH":{"ok":true,"v":78,"valido":"true"},"G3052353":{"ok":true,"v":57,"valido":"true"},"ABU721":{"ok":true,"v":19,"valido":"true"},"063WAE":{"ok":true,"v":48,"valido":"true"},"TJ353TD":{"ok":true,"v":91,"valido":"true"},"G054MVD":{"ok":true,"v":98,"valido":"true"},"I9397745":{"ok":true,"v":35,"valido":"true"},"EFG650":{"ok":true,"v":91,"valido":"true"},"215BTG":{"ok":true,"v":52,"valido":"true"},"GE538ZQ":{"ok":true,"v":21,"valido":"true"},"D508ALA":{"ok":true,"v":38,"valido":"true"},"Q1338554":{"ok":true,"v":47,"valido":"true"},"RZN334":{"ok":true,"v":14,"valido":"true"},"307FNL":{"ok":true,"v":33,"valido":"true"},"FU665QN":{"ok":true,"v":71,"valido":"true"},"M853VGD":{"ok":true,"v":24,"valido":"true"},"X3937367":{"ok":true,"v":74,"valido":"true"},"AZI899":{"ok":true,"v":36,"valido":"true"},"321RLY":{"ok":true,"v":84,"valido":"true"},"HI750FX":{"ok":true,"v":32,"valido":"true"},"S750DGP":{"ok":true,"v":62,"valido":"true"},"L0135769":{"ok":true,"v":13,"valido":"true"},"FYP811":{"ok":true,"v":58,"valido":"true"},"143UUN":{"ok":true,"v":27,"valido":"true"},"QR056DA":{"ok":true,"v":96,"valido":"true"},"N709CHA":{"ok":true,"v":34,"valido":"true"},"Y7012277":{"ok":true,"v":89,"valido":"true"},"ISL447":{"ok":true,"v":49,"valido":"true"},"933LRZ":{"ok":true,"v":95,"valido":"true"},"XT382DV":{"ok":true,"v":52,"valido":"true"},"L734LTD":{"ok":true,"v":43,"valido":"true"},"G4272779":{"ok":true,"v":92,"valido":"true"},"LIS166":{"ok":true,"v":92,"valido":"true"},"499VRV":{"ok":true,"v":15,"valido":"true"},"XM106UD":{"ok":true,"v":69,"valido":"true"},"H863CMF":{"ok":true,"v":68,"valido":"true"},"Q3413819":{"ok":true,"v":38,"valido":"true"},"XKS766":{"ok":true,"v":63,"valido":"true"},"665UOB":{"ok":true,"v":19,"valido":"true"},"FX326CR":{"ok":true,"v":26,"valido":"true"},"V664JQO":{"ok":true,"v":53,"valido":"true"},"W5004976":{"ok":true,"v":22,"valido":"true"},"MRT544":{"ok":true,"v":15,"valido":"true"},"443GRP":{"ok":true,"v":98,"valido":"true"},"AU741KY":{"ok":true,"v":74,"valido":"true"},"P010CNB":{"ok":true,"v":64,"valido":"true"},"W2908544":{"ok":true,"v":23,"valido":"true"},"WME066":{"ok":true,"v":77,"valido":"true"},"814FJB":{"ok":true,"v":23,"valido":"true"},"YL365FW":{"ok":true,"v":14,"valido":"true"},"A130HCH":{"ok":true,"v":27,"valido":"true"},"F6911219":{"ok":true,"v":92,"valido":"true"},"FBR914":{"ok":true,"v":72,"valido":"true"},"081QOK":{"ok":true,"v":64,"valido":"true"},"VX043SQ":{"ok":true,"v":62,"valido":"true"},"Q430BMS":{"ok":true,"v":32,"valido":"true"},"S7301909":{"ok":true,"v":74,"valido":"true"},"WAB387":{"ok":true,"v":35,"valido":"true"},"768GXN":{"ok":true,"v":38,"valido":"true"},"EC625FR":{"ok":true,"v":21,"valido":"true"},"C469FPD":{"ok":true,"v":32,"valido":"true"},"N0327671":{"ok":true,"v":98,"valido":"true"},"TJU352":{"ok":true,"v":62,"valido":"true"},"310WZI":{"ok":true,"v":65,"valido":"true"},"CV529ND":{"ok":true,"v":77,"valido":"true"},"M471LPH":{"ok":true,"v":64,"valido":"true"},"Q0324718":{"ok":true,"v":88,"valido":"true"},"OJT007":{"ok":true,"v":99,"valido":"true"},"836CGZ":{"ok":true,"v":35,"valido":"true"},"QR142UB":{"ok":true,"v":84,"valido":"true"},"S924ACO":{"ok":true,"v":47,"valido":"true"},"Q1496463":{"ok":true,"v":87,"valido":"true"},"ERF003":{"ok":true,"v":65,"valido":"true"},"591OJL":{"ok":true,"v":82,"valido":"true"},"VZ912HF":{"ok":true,"v":54,"valido":"true"},"O939HKC":{"ok":true,"v":31,"valido":"true"},"T9331274":{"ok":true,"v":92,"valido":"true"},"BJG230":{"ok":true,"v":32,"valido":"true"},"166KAY":{"ok":true,"v":81,"valido":"true"},"TI444PD":{"ok":true,"v":98,"valido":"true"},"K658AST":{"ok":true,"v":17,"valido":"true"},"V3700365":{"ok":true,"v":24,"valido":"true"},"HNS384":{"ok":true,"v":84,"valido":"true"},"913NEZ":{"ok":true,"v":93,"valido":"true"},"ZV911MV":{"ok":true,"v":24,"valido":"true"},"E613DFS":{"ok":true,"v":89,"valido":"true"},"C8430716":{"ok":true,"v":65,"valido":"true"},"TGF693":{"ok":true,"v":36,"valido":"true"},"053EZZ":{"ok":true,"v":47,"valido":"true"},"CI073VN":{"ok":true,"v":25,"valido":"true"},"V892EJY":{"ok":true,"v":24,"valido":"true"},"K8246968":{"ok":true,"v":25,"valido":"true"},"PAF392":{"ok":true,"v":16,"valido":"true"},"094BZQ":{"ok":true,"v":22,"valido":"true"},"HI368XA":{"ok":true,"v":22,"valido":"true"},"V305TXM":{"ok":true,"v":53,"valido":"true"},"F7818057":{"ok":true,"v":63,"valido":"true"},"IRJ486":{"ok":true,"v":41,"valido":"true"},"018YZO":{"ok":true,"v":75,"valido":"true"},"ZL031IL":{"ok":true,"v":52,"valido":"true"},"C188EXX":{"ok":true,"v":28,"valido":"true"},"A5801254":{"ok":true,"v":25,"valido":"true"},"GLY549":{"ok":true,"v":78,"valido":"true"},"856RTS":{"ok":true,"v":46,"valido":"true"},"DN989SN":{"ok":true,"v":79,"valido":"true"},"V191QFQ":{"ok":true,"v":27,"valido":"true"},"Q1515810":{"ok":true,"v":12,"valido":"true"},"GDB911":{"ok":true,"v":38,"valido":"true"},"893QEV":{"ok":true,"v":93,"valido":"true"},"PX867RH":{"ok":true,"v":83,"valido":"true"},"I707BCU":{"ok":true,"v":15,"valido":"true"},"L2492641":{"ok":true,"v":91,"valido":"true"},"EPR796":{"ok":true,"v":77,"valido":"true"},"587DPN":{"ok":true,"v":53,"valido":"true"},"AH537WN":{"ok":true,"v":89,"valido":"true"},"T034KTY":{"ok":true,"v":73,"valido":"true"},"X6007388":{"ok":true,"v":86,"valido":"true"},"MYT058":{"ok":true,"v":92,"valido":"true"},"740XNN":{"ok":true,"v":76,"valido":"true"},"IV671OJ":{"ok":true,"v":57,"valido":"true"},"Y207OVT":{"ok":true,"v":69,"valido":"true"},"A6379544":{"ok":true,"v":47,"valido":"true"},"XNP622":{"ok":true,"v":21,"valido":"true"},"302SGN":{"ok":true,"v":12,"valido":"true"},"HW373OZ":{"ok":true,"v":12,"valido":"true"},"D077YXI":{"ok":true,"v":27,"valido":"true"},"Z3326523":{"ok":true,"v":42,"valido":"true"},"CXW969":{"ok":true,"v":11,"valido":"true"},"471UKZ":{"ok":true,"v":62,"valido":"true"},"UC665BN":{"ok":true,"v":79,"valido":"true"},"R580NYK":{"ok":true,"v":63,"valido":"true"},"M3886889":{"ok":true,"v":14,"valido":"true"},"KMH210":{"ok":true,"v":46,"valido":"true"},"617PAQ":{"ok":true,"v":95,"valido":"true"},"TY964KT":{"ok":true,"v":31,"valido":"true"},"X615GVA":{"ok":true,"v":98,"valido":"true"},"U4056700":{"ok":true,"v":76,"valido":"true"},"BQA483":{"ok":true,"v":93,"valido":"true"},"995VNA":{"ok":true,"v":64,"valido":"true"},"NN550OC":{"ok":true,"v":34,"valido":"true"},"O535CJQ":{"ok":true,"v":99,"valido":"true"},"M6592937":{"ok":true,"v":41,"valido":"true"},"ZOV141":{"ok":true,"v":71,"valido":"true"},"957LOU":{"ok":true,"v":48,"valido":"true"},"MW806TM":{"ok":true,"v":75,"valido":"true"},"N822IBO":{"ok":true,"v":39,"valido":"true"},"Z6888082":{"ok":true,"v":76,"valido":"true"},"EMG859":{"ok":true,"v":95,"valido":"true"},"397FQK":{"ok":true,"v":15,"valido":"true"},"VM926JK":{"ok":true,"v":72,"valido":"true"},"W060TIW":{"ok":true,"v":31,"valido":"true"},"B7998025":{"ok":true,"v":31,"valido":"true"},"PSW721":{"ok":true,"v":27,"valido":"true"},"025LFZ":{"ok":true,"v":25,"valido":"true"},"JZ080FN":{"ok":true,"v":47,"valido":"true"},"F563BHV":{"ok":true,"v":58,"valido":"true"},"E5782539":{"ok":true,"v":93,"valido":"true"},"EAQ731":{"ok":true,"v":12,"valido":"true"},"156LVM":{"ok":true,"v":47,"valido":"true"},"HD311ZB":{"ok":true,"v":48,"valido":"true"},"Q943MRA":{"ok":true,"v":35,"valido":"true"},"E2770781":{"ok":true,"v":86,"valido":"true"},"NMB466":{"ok":true,"v":25,"valido":"true"},"277STI":{"ok":true,"v":39,"valido":"true"},"PN439ED":{"ok":true,"v":99,"valido":"true"},"T441MZE":{"ok":true,"v":32,"valido":"true"},"G9490810":{"ok":true,"v":85,"valido":"true"},"NQO755":{"ok":true,"v":73,"valido":"true"},"124UZR":{"ok":true,"v":55,"valido":"true"},"AA783NA":{"ok":true,"v":19,"valido":"true"},"T477GZO":{"ok":true,"v":58,"valido":"true"},"T1147046":{"ok":true,"v":23,"valido":"true"},"UGQ471":{"ok":true,"v":88,"valido":"true"},"305YFD":{"ok":true,"v":14,"valido":"true"},"ZZ978PF":{"ok":true,"v":37,"valido":"true"},"R758NFS":{"ok":true,"v":38,"valido":"true"},"C5846258":{"ok":true,"v":11,"valido":"true"},"XZR866":{"ok":true,"v":77,"valido":"true"},"224HIE":{"ok":true,"v":64,"valido":"true"},"WE053YR":{"ok":true,"v":94,"valido":"true"},"M378UFZ":{"ok":true,"v":26,"valido":"true"},"U7263335":{"ok":true,"v":38,"valido":"true"},"SPT465":{"ok":true,"v":27,"valido":"true"},"935XVF":{"ok":true,"v":27,"valido":"true"},"AK118IV":{"ok":true,"v":11,"valido":"true"},"I434FCA":{"ok":true,"v":51,"valido":"true"},"L7091428":{"ok":true,"v":13,"valido":"true"},"LJG227":{"ok":true,"v":18,"valido":"true"},"470WPD":{"ok":true,"v":42,"valido":"true"},"QT052NS":{"ok":true,"v":82,"valido":"true"},"Y804VUG":{"ok":true,"v":99,"valido":"true"},"X1481833":{"ok":true,"v":28,"valido":"true"},"LRL091":{"ok":true,"v":27,"valido":"true"},"779DZD":{"ok":true,"v":81,"valido":"true"},"XI261EM":{"ok":true,"v":54,"valido":"true"},"O309HKO":{"ok":true,"v":29,"valido":"true"},"F7006639":{"ok":true,"v":49,"valido":"true"},"TJY861":{"ok":true,"v":16,"valido":"true"},"390OKH":{"ok":true,"v":94,"valido":"true"},"GF111JU":{"ok":true,"v":52,"valido":"true"},"N773FJF":{"ok":true,"v":95,"valido":"true"},"Y7460832":{"ok":true,"v":57,"valido":"true"},"NIH974":{"ok":true,"v":75,"valido":"true"},"912PKX":{"ok":true,"v":85,"valido":"true"},"UX834BI":{"ok":true,"v":91,"valido":"true"},"C930ZON":{"ok":true,"v":67,"valido":"true"},"AAAA999":{"ok":true,"v":47,"valido":"El dominio especificado no tiene un formato válido."},"BBBB111":{"ok":true,"v":25,"valido":"El dominio especificado no tiene un formato válido."},"CCCC222":{"ok":true,"v":42,"valido":"El dominio especificado no tiene un formato válido."},"ABCABC":{"ok":true,"v":21,"valido":"El dominio especificado no tiene un formato válido."},"LLLL123":{"ok":true,"v":47,"valido":"El dominio especificado no tiene un formato válido."},"ZZZZ000":{"ok":true,"v":41,"valido":"El dominio especificado no tiene un formato válido."},"AAAAAAA1":{"ok":false,"v":"No es válida la patente ingresada.","valido":"El dominio especificado no tiene un formato válido."},"ABABAB":{"ok":true,"v":36,"valido":"El dominio especificado no tiene un formato válido."}};

if (process.argv.includes('--dump-golden')) {
	if (!orig) {
		console.error('--dump-golden necesita el export de AGIP en web-scripts/files.');
		process.exit(2);
	}
	const out = {};
	for (const p of suite) {
		let v;
		try { v = { ok: true, v: orig.getDv(p) }; } catch (e) { v = { ok: false, v: String(e.message) }; }
		v.valido = String(orig.valido(p));
		out[p] = v;
	}
	console.log(JSON.stringify(out));
	process.exit(0);
}

// ---- objeto de referencia: el original, o los vectores dorados -------------
const ref = orig || {
	getDv(p) {
		const g = GOLDEN[p];
		if (!g) throw new Error('caso sin vector dorado: ' + p);
		if (!g.ok) throw new Error(g.v);
		return g.v;
	},
	valido(p) {
		const g = GOLDEN[p];
		if (!g) return 'caso sin vector dorado';
		return g.valido === 'true' ? true : g.valido;
	}
};

// ---- corrida ----------------------------------------------------------------
let fails = 0, checked = 0;
const mismatches = [];
for (const p of suite) {
	let a, b;
	try { a = { ok: true, v: mine.getDv(p) }; } catch (e) { a = { ok: false, v: String(e.message) }; }
	try { b = { ok: true, v: ref.getDv(p) }; } catch (e) { b = { ok: false, v: String(e.message) }; }
	checked++;
	const same = a.ok === b.ok && String(a.v) === String(b.v);
	if (!same) { fails++; mismatches.push(`${p}: ours=${JSON.stringify(a)} ref=${JSON.stringify(b)}`); }

	// ademas: valido() y validoDv() deben coincidir (solo contra el original)
	if (orig) {
		const va = mine.valido(p), vb = orig.valido(p);
		checked++;
		if (String(va) !== String(vb)) { fails++; mismatches.push(`valido(${p}): ${va} != ${vb}`); }
		if (va === true) {
			const dv = mine.getDv(p);
			const da = mine.validoDv(p, String(dv)), db = orig.validoDv(p, String(dv));
			checked++;
			if (String(da) !== String(db)) { fails++; mismatches.push(`validoDv(${p}): ${da} != ${db}`); }
		}
	}
}

if (orig) {
	console.log('Modo               : paridad contra el original de AGIP');
	console.log('Original           : ' + originalPath);
	console.log('SHA-256 del original: ' + crypto.createHash('sha256')
		.update(fs.readFileSync(originalPath, 'utf8')).digest('hex'));
} else {
	console.log('Modo               : vectores dorados congelados (sin export de AGIP)');
}
console.log('Casos              : ' + suite.length + '  (comprobaciones: ' + checked + ')');
if (fails) {
	console.log('FALLOS: ' + fails);
	mismatches.slice(0, 40).forEach(m => console.log('  ' + m));
	process.exit(1);
}
console.log('OK: dv.js replica exactamente al comportamiento de referencia.');

// --- tabla de resultados para documentar ---
console.log('\nMuestra de DVs:');
['QQ999QQ', 'AB123CD', 'ABC123', 'A1234567', '123ABC', 'A123BCD'].forEach(p => {
	let out;
	try { out = mine.getDv(p); } catch (e) { out = 'ERROR: ' + e.message; }
	console.log('  ' + p.padEnd(10) + ' -> ' + out);
});
