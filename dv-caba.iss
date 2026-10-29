; ============================================================================
;  dv-caba.iss - Calculadora PORTABLE del DÍGITO VERIFICADOR de patentes CABA
;  Sitio objetivo: https://lb.agip.gob.ar/ConsultaPat/
;
;  Esto NO es un instalador: el binario nunca muestra el asistente de Inno.
;  InitializeSetup() crea una TForm propia, muestra la GUI y termina el
;  proceso con ExitProcess(0). No se instala nada, no hay desinstalador.
;
;  Algoritmo: port 1:1 de patente.getDv()
;             (https://lb.agip.gob.ar/libFe/js/patente.js, SHA-256 aaf9d407...)
;             Verificado contra el original exportado por REA: 432 casos /
;             1282 comprobaciones (test-paridad.js). El binario ejecuta un
;             autotest de humo (26 letras + negativos) antes de la GUI y del
;             modo archivo; la bateria completa queda en test-paridad.js.
;
;  Autoria: mikear - https://github.com/mikear/DV
;  Herramienta NO oficial, sin afiliación con AGIP. Ver DISCLAIMER.md.
;
;  El binario NO invoca cmd ni powershell para calcular ni para el
;  portapapeles: usa API nativa de Win32 (user32/kernel32) y el enlace del
;  pie abre el navegador solo a pedido.
;
;  Modos de uso:
;    dv-caba-portable.exe                     -> abre la app
;    dv-caba-portable.exe QQ999QQ             -> app con el dominio precargado
;    dv-caba-portable.exe QQ999QQ C:\r.txt    -> escribe "DV=99" y sale, exit 0/2
;    dv-caba-portable.exe --copy 15           -> copia al portapapeles, exit 0/2
; ============================================================================

#define AppName "DV Patentes CABA"
#define AppVersion "1.1.2"
#define OutputName "dv-caba"
#define Autor "mikear"
#define RepoURL "https://github.com/mikear/DV"
#define SiteURL "https://lb.agip.gob.ar/ConsultaPat/"

[Setup]
AppId={{5B0E2C4A-9F31-4E77-8A62-3D1C7F0A9B21}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#Autor}
AppPublisherURL={#RepoURL}
AppSupportURL={#RepoURL}
AppUpdatesURL={#RepoURL}
VersionInfoVersion={#AppVersion}
VersionInfoProductVersion={#AppVersion}
VersionInfoTextVersion={#AppVersion}
VersionInfoCompany={#Autor}
VersionInfoDescription=Calculadora portable del dígito verificador de patentes CABA
VersionInfoProductName={#AppName}
VersionInfoOriginalFileName={#OutputName}-portable.exe
VersionInfoCopyright=Copyright (C) 2026 {#Autor} - {#RepoURL} - Herramienta no oficial
SetupIconFile=iconos\dv-caba.ico
DefaultDirName={autopf}\dv-caba
DisableDirPage=yes
DisableProgramGroupPage=yes
DisableReadyPage=yes
DisableWelcomePage=yes
DisableStartupPrompt=yes
PrivilegesRequired=lowest
Uninstallable=no
CreateAppDir=no
OutputDir=dist
OutputBaseFilename={#OutputName}-portable
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=no
RestartApplications=no
ShowLanguageDialog=no

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
Source: "iconos\preview-64.png"; DestDir: "{tmp}"; Flags: dontcopy noencryption
Source: "iconos\accent-teal.png"; DestDir: "{tmp}"; Flags: dontcopy noencryption
; Arte de chapas (fondos + glifos por estilo). Las muestras de QA no viajan.
Source: "iconos\chapas\*.png"; Excludes: "muestra-*.png"; DestDir: "{tmp}"; Flags: dontcopy noencryption

[Code]
#include "iconos\chapas\chapas-layout.iss"

const
  { Tabla de letras del original. A=14 B=01 C=00 ... Z=17 }
  LETRAS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  CODIGOS = '1401001605201909240721080413252218100206122311031517';
  CF_UNICODETEXT = 13;
  GMEM_MOVEABLE = $0002;
  GWL_STYLE = -16;
  ES_CENTER = $0001;

  { glifos Segoe MDL2 Assets (NO son emojis) - literales anchos, ya que
    Chr() trunca al byte bajo y produce caracteres incorrectos }
  GLIFO_OK     = #$E73E;   { check }
  GLIFO_ERROR  = #$E711;   { cancel / X }
  GLIFO_COPIAR = #$E8C8;   { copy }
  GLIFO_ABRIR  = #$E8A7;   { open in new window }
  GLIFO_LINK   = #$E71B;   { link }

  { tamano del recuadro de la chapa, en px logicos }
  CHAPA_BOX_ALTO = 139;

var
  AppForm: TForm;
  Acento, IconoApp: TBitmapImage;
  ChapaBg: TBitmapImage;
  ChapaG1, ChapaG2, ChapaG3, ChapaG4: TBitmapImage;
  ChapaG5, ChapaG6, ChapaG7, ChapaG8: TBitmapImage;
  ChapaExtraidos: TStringList;
  LblChapa: TNewStaticText;
  { geometria del render actual de la chapa: escala (px de pantalla por
    unidad de placa) y origen del PNG de fondo }
  ChapaS: Extended;
  ChapaOx, ChapaOy: Integer;
  LblSec1, LblSec2, LblSec3: TNewStaticText;
  LblCopiarDom, LblLinkIcon, LblEstadoIcon: TNewStaticText;
  LblEstado, LblLink, LblAyuda, LblAviso: TNewStaticText;
  LblAutorIcon, LblAutor: TNewStaticText;
  EdtDominio, EdtResultado: TNewEdit;
  BtnCalcular, BtnCopiar, BtnCerrar: TNewButton;
  Dpi: Integer;

{ ---------------------------------------------------------------------- }
{ APIs nativas de Win32 (sin crear procesos externos)                    }
{ ---------------------------------------------------------------------- }

function GetDpiForWindow(AWnd: Integer): Integer;
  external 'GetDpiForWindow@user32.dll stdcall';

function GetWindowLong(AWnd, AIndex: Integer): Longint;
  external 'GetWindowLongW@user32.dll stdcall';

function SetWindowLong(AWnd, AIndex: Integer; ANewLong: Longint): Longint;
  external 'SetWindowLongW@user32.dll stdcall';

function HideCaret(AWnd: Integer): Integer;
  external 'HideCaret@user32.dll stdcall';

function OpenClipboard(AWnd: Integer): Integer;
  external 'OpenClipboard@user32.dll stdcall';

function CloseClipboard(): Integer;
  external 'CloseClipboard@user32.dll stdcall';

function EmptyClipboard(): Integer;
  external 'EmptyClipboard@user32.dll stdcall';

function SetClipboardData(AFormat, AData: Integer): Integer;
  external 'SetClipboardData@user32.dll stdcall';

function GlobalAlloc(AFlags, ABytes: Integer): Integer;
  external 'GlobalAlloc@kernel32.dll stdcall';

function GlobalLock(AHMem: Integer): Integer;
  external 'GlobalLock@kernel32.dll stdcall';

function GlobalUnlock(AHMem: Integer): Integer;
  external 'GlobalUnlock@kernel32.dll stdcall';

function GlobalFree(AHMem: Integer): Integer;
  external 'GlobalFree@kernel32.dll stdcall';

function lstrcpyW(ADest: Integer; ASrc: String): Integer;
  external 'lstrcpyW@kernel32.dll stdcall';

procedure ExitProcess(ACode: Integer);
  external 'ExitProcess@kernel32.dll stdcall';

function RGB(R, G, B: Integer): Integer;
begin
  Result := R or (G shl 8) or (B shl 16);
end;

function CopiarPortapapeles(const Texto: String): Boolean;
var
  H, P: Integer;
begin
  Result := False;
  H := GlobalAlloc(GMEM_MOVEABLE, (Length(Texto) + 1) * 2);
  if H = 0 then Exit;
  P := GlobalLock(H);
  if P = 0 then begin
    GlobalFree(H);
    Exit;
  end;
  lstrcpyW(P, Texto);
  GlobalUnlock(H);
  if OpenClipboard(0) = 0 then begin
    GlobalFree(H);
    Exit;
  end;
  EmptyClipboard();
  if SetClipboardData(CF_UNICODETEXT, H) <> 0 then
    Result := True
  else
    GlobalFree(H);
  CloseClipboard();
end;

{ escala un valor en px de 96 DPI al DPI actual }
function Sc(V: Integer): Integer;
begin
  Result := (V * Dpi + 48) div 96;
end;

function EsLetra(C: Char): Boolean;
begin
  Result := (C >= 'A') and (C <= 'Z');
end;

function EsDigito(C: Char): Boolean;
begin
  Result := (C >= '0') and (C <= '9');
end;

{ ---------------------------------------------------------------------- }
{ Chapa del dominio: render con overlay de PNGs (+BOM layout generado por }
{ ExportarChapas.java de patentes-javafx). Coordenadas en los comentarios }
{ son de placa a escala 1, igual que PlateCanvas.java.                    }
{ ---------------------------------------------------------------------- }

{ Devuelve el token Indice (0-based) de una lista CSV de enteros. }
function TokensCsv(const Csv: String; Indice, ValorDef: Integer): Integer;
var
  I, P: Integer;
  Tok: String;
begin
  Tok := Csv;
  for I := 0 to Indice - 1 do begin
    P := Pos(',', Tok);
    if P > 0 then
      Tok := Copy(Tok, P + 1, MaxInt)
    else begin
      Tok := '';
      Break;
    end;
  end;
  P := Pos(',', Tok);
  if P > 0 then
    Tok := Copy(Tok, 1, P - 1);
  Tok := Trim(Tok);
  if Tok = '' then
    Result := ValorDef
  else
    Result := StrToIntDef(Tok, ValorDef);
end;

{ Indice de glifo: A..Z = 0..25, 0..9 = 26..35 (orden de los CSV generados). }
function IndiceGlifo(const C: Char): Integer;
begin
  if (C >= 'A') and (C <= 'Z') then
    Result := Ord(C) - Ord('A')
  else
    Result := 26 + (Ord(C) - Ord('0'));
end;

{ Indice de dígito solo (0..9): los CSV de vieja-m y vieja-d tienen 10
  entradas indexadas por dígito, a diferencia de los conjuntos de 36. }
function IndiceDigito(const C: Char): Integer;
begin
  Result := Ord(C) - Ord('0');
end;

{ Nombre de archivo del tile: letras A.png, digitos d5.png. }
function NombreGlifo(const Conjunto: String; const C: Char): String;
begin
  if (C >= '0') and (C <= '9') then
    Result := 'g-' + Conjunto + '-d' + C + '.png'
  else
    Result := 'g-' + Conjunto + '-' + C + '.png';
end;

{ Extrae un PNG al directorio temporal una sola vez por proceso. }
procedure ExtraerTmp(const Nombre: String);
begin
  if ChapaExtraidos.IndexOf(Nombre) < 0 then begin
    ExtractTemporaryFile(Nombre);
    ChapaExtraidos.Add(Nombre);
  end;
end;

procedure OcultarChapa;
begin
  ChapaBg.Visible := False;
  ChapaG1.Visible := False;
  ChapaG2.Visible := False;
  ChapaG3.Visible := False;
  ChapaG4.Visible := False;
  ChapaG5.Visible := False;
  ChapaG6.Visible := False;
  ChapaG7.Visible := False;
  ChapaG8.Visible := False;
end;

{ Coloca un glifo.
  Conjunto:  1=VJL 2=VJM 3=VJD 4=NAC 5=MTN 6=MSR 7=MTM (consts de layout).
  Idx:       IndiceGlifo(C).
  XU:        centro de la celda (Centrado) o ancla izquierda del texto
             (Vieja), en unidades de placa.
  BU:        baseline de la celda, en unidades de placa.
  YO/TW/TH:  constantes CSV del layout; XO solo para los conjuntos vieja. }
procedure PonerGlifo(Slot: TBitmapImage; Conjunto: Integer; const Archivo: String;
  Idx: Integer; const XU, BU: Extended; Centrado: Boolean);
var
  StrA, StrX, StrY, StrW, StrH: String;
  TW_, TH_, YOs, XOs: Integer;
  X, Y, Wd, Hd: Integer;
begin
  case Conjunto of
    1: begin
         StrA := CHAPA_VJL_ADV; StrX := CHAPA_VJL_XO; StrY := CHAPA_VJL_YO;
         StrW := CHAPA_VJL_TW;  StrH := CHAPA_VJL_TH;
       end;
    2: begin
         StrA := CHAPA_VJM_ADV; StrX := CHAPA_VJM_XO; StrY := CHAPA_VJM_YO;
         StrW := CHAPA_VJM_TW;  StrH := CHAPA_VJM_TH;
       end;
    3: begin
         StrA := CHAPA_VJD_ADV; StrX := CHAPA_VJD_XO; StrY := CHAPA_VJD_YO;
         StrW := CHAPA_VJD_TW;  StrH := CHAPA_VJD_TH;
       end;
    4: begin
         StrA := CHAPA_NAC_ADV; StrX := ''; StrY := CHAPA_NAC_YO;
         StrW := CHAPA_NAC_TW;  StrH := CHAPA_NAC_TH;
       end;
    5: begin
         StrA := CHAPA_MTN_ADV; StrX := ''; StrY := CHAPA_MTN_YO;
         StrW := CHAPA_MTN_TW;  StrH := CHAPA_MTN_TH;
       end;
    6: begin
         StrA := CHAPA_MSR_ADV; StrX := ''; StrY := CHAPA_MSR_YO;
         StrW := CHAPA_MSR_TW;  StrH := CHAPA_MSR_TH;
       end;
    7: begin
         StrA := CHAPA_MTM_ADV; StrX := ''; StrY := CHAPA_MTM_YO;
         StrW := CHAPA_MTM_TW;  StrH := CHAPA_MTM_TH;
       end;
  else
    Exit;
  end;
  TW_ := TokensCsv(StrW, Idx, 0);
  TH_ := TokensCsv(StrH, Idx, 0);
  YOs := TokensCsv(StrY, Idx, 0);
  { ojo: divisor de enteros trunca en este Pascal Script; los factores
    flotantes 0.01/0.005 equivalen a /100 y /200 en unidades de placa }
  if Centrado then
    X := ChapaOx + Round((XU - TW_ * 0.005) * ChapaS)
  else begin
    XOs := TokensCsv(StrX, Idx, 0);
    X := ChapaOx + Round((XU + XOs * 0.01) * ChapaS);
  end;
  Y := ChapaOy + Round((BU + YOs * 0.01) * ChapaS);
  Wd := Round(TW_ * 0.01 * ChapaS);
  Hd := Round(TH_ * 0.01 * ChapaS);
  ExtraerTmp(Archivo);
  Slot.PngImage.LoadFromFile(ExpandConstant('{tmp}\') + Archivo);
  Slot.Left := X;
  Slot.Top := Y;
  Slot.Width := Wd;
  Slot.Height := Hd;
  Slot.Visible := True;
end;

{ Devuelve el slot N (1..8). }
function ChapaSlotPorNum(N: Integer): TBitmapImage;
begin
  case N of
    1: Result := ChapaG1;
    2: Result := ChapaG2;
    3: Result := ChapaG3;
    4: Result := ChapaG4;
    5: Result := ChapaG5;
    6: Result := ChapaG6;
    7: Result := ChapaG7;
    8: Result := ChapaG8;
  else
    Result := ChapaG1;
  end;
end;

{ Coloca un grupo centrado de caracteres (Desde..Hasta) en un conjunto
  de glifos con recorte centrado (NAC/MTN/MSR/MTM). La tinta queda
  centrada en la celda: cellC = CXu - total/2 + sum(prev) + adv_i/2.
  Los slots quedan numerados por posicion absoluta del caracter. }
procedure GrupoCentrado(const Dom: String; const AAdv: String;
  CXu, BU: Extended; Desde, Hasta: Integer; Conjunto: Integer;
  const NomArch: String);
var
  Q, Idx, Tok, TokTotal: Integer;
  P: Extended;
begin
  TokTotal := 0;
  for Q := Desde to Hasta do
    TokTotal := TokTotal + TokensCsv(AAdv, IndiceGlifo(Dom[Q]), 0);
  P := 0;
  for Q := Desde to Hasta do begin
    Idx := IndiceGlifo(Dom[Q]);
    Tok := TokensCsv(AAdv, Idx, 0);
    PonerGlifo(ChapaSlotPorNum(Q), Conjunto, NombreGlifo(NomArch, Dom[Q]), Idx,
      CXu - TokTotal * 0.005 + P + Tok * 0.005, BU, True);
    P := P + Tok * 0.01;
  end;
end;

{ Renderiza la chapa del dominio ya validado. Geometria copiada de
  PlateCanvas.java (los coeficientes son los mismos del dibujo original). }
procedure MostrarChapa(const Dom: String);
var
  L, M, Q, BoxW: Integer;
  WP, HP: Integer;
  Sn, Sh, B, X0, X1, P: Extended;
  Idx: Integer;
  BgArch: String;
begin
  L := Length(Dom);
  if (L < 6) or (L > 8) then begin
    OcultarChapa;
    Exit;
  end;
  OcultarChapa;

  M := Sc(14);
  BoxW := AppForm.ClientWidth - 2 * M;

  { dimensiones de la placa (unidades 1/100 = px a escala 1) y estilo }
  if L = 8 then begin
    WP := 780; HP := 230;
    BgArch := 'bg-vieja.png';
  end else if (L = 6) and EsLetra(Dom[1]) and EsLetra(Dom[2]) and EsLetra(Dom[3]) then begin
    WP := 780; HP := 254;
    BgArch := 'bg-nacional.png';
  end else if (L = 6) and EsDigito(Dom[1]) and EsDigito(Dom[2]) and EsDigito(Dom[3]) then begin
    WP := 320; HP := 276;
    BgArch := 'bg-moto-nacional.png';
  end else if EsLetra(Dom[1]) and EsLetra(Dom[2]) and EsDigito(Dom[3]) then begin
    WP := 780; HP := 254;
    BgArch := 'bg-mercosur.png';
  end else begin
    WP := 320; HP := 276;
    BgArch := 'bg-moto-mercosur.png';
  end;

  Sn := BoxW * 1.0 / WP;
  Sh := Sc(CHAPA_BOX_ALTO) * 1.0 / HP;
  if Sh < Sn then
    ChapaS := Sh
  else
    ChapaS := Sn;
  ChapaOx := M + (BoxW - Round(WP * ChapaS)) div 2;
  ChapaOy := Sc(200);

  ExtraerTmp(BgArch);
  ChapaBg.PngImage.LoadFromFile(ExpandConstant('{tmp}\') + BgArch);
  ChapaBg.Left := ChapaOx;
  ChapaBg.Top := ChapaOy;
  ChapaBg.Width := Round(WP * ChapaS);
  ChapaBg.Height := Round(HP * ChapaS);
  ChapaBg.Visible := True;

  if L = 8 then begin
    { vieja: letra enorme + millon chico + 6 digitos, grupos a la izquierda;
      XL=780*0.045, B letra=230*0.78, B millon=230*0.36, B resto=230*0.80,
      gaps 780*0.010 y 780*0.030 }
    X0 := 780 * 0.045;
    PonerGlifo(ChapaG1, 1, NombreGlifo('vieja-l', Dom[1]),
      IndiceGlifo(Dom[1]), X0, 230 * 0.78, False);
    X0 := X0 + TokensCsv(CHAPA_VJL_ADV, IndiceGlifo(Dom[1]), 0) * 0.01 + 780 * 0.010;
    PonerGlifo(ChapaG2, 2, NombreGlifo('vieja-m', Dom[2]),
      IndiceDigito(Dom[2]), X0, 230 * 0.36, False);
    X1 := X0 + TokensCsv(CHAPA_VJM_ADV, IndiceDigito(Dom[2]), 0) * 0.01 + 780 * 0.030;
    P := 0;
    for Q := 3 to 8 do begin
      Idx := IndiceDigito(Dom[Q]);
      PonerGlifo(ChapaSlotPorNum(Q), 3, NombreGlifo('vieja-d', Dom[Q]), Idx,
        X1 + P, 230 * 0.80, False);
      P := P + TokensCsv(CHAPA_VJD_ADV, Idx, 0) * 0.01;
    end;
  end else if (L = 6) and EsLetra(Dom[1]) then begin
    { nacional auto: fy=254*0.285, bandaInf=254*0.105, base=fy+fh*0.80;
      letras cx=780*0.325, digitos cx=780*0.675 }
    B := 254 * 0.285 + (254 - 254 * 0.285 - 254 * 0.105) * 0.80;
    GrupoCentrado(Dom, CHAPA_NAC_ADV, 780 * 0.325, B, 1, 3, 4, 'nacional');
    GrupoCentrado(Dom, CHAPA_NAC_ADV, 780 * 0.675, B, 4, 6, 4, 'nacional');
  end else if L = 6 then begin
    { moto nacional: fy=276*0.30, fh=276-fy-276*0.115, cx=320*0.50;
      baseline digitos fy+fh*0.40, letras fy+fh*0.88 }
    GrupoCentrado(Dom, CHAPA_MTN_ADV, 320 * 0.50,
      276 * 0.30 + (276 - 276 * 0.30 - 276 * 0.115) * 0.40, 1, 3, 5,
      'moto-nacional');
    GrupoCentrado(Dom, CHAPA_MTN_ADV, 320 * 0.50,
      276 * 0.30 + (276 - 276 * 0.30 - 276 * 0.115) * 0.88, 4, 6, 5,
      'moto-nacional');
  end else if EsLetra(Dom[1]) and EsLetra(Dom[2]) then begin
    { mercosur auto: p/d/s en cx=780*0.155/0.500/0.845, baseline 254*0.855 }
    GrupoCentrado(Dom, CHAPA_MSR_ADV, 780 * 0.155, 254 * 0.855, 1, 2, 6,
      'mercosur');
    GrupoCentrado(Dom, CHAPA_MSR_ADV, 780 * 0.500, 254 * 0.855, 3, 5, 6,
      'mercosur');
    GrupoCentrado(Dom, CHAPA_MSR_ADV, 780 * 0.845, 254 * 0.855, 6, 7, 6,
      'mercosur');
  end else begin
    { moto mercosur: fila 1 LDDD cx=320*0.52 baseline 276*0.575;
      fila 2 LLL cx=320*0.52 baseline 276*0.885 }
    GrupoCentrado(Dom, CHAPA_MTM_ADV, 320 * 0.52, 276 * 0.575, 1, 4, 7,
      'moto-mercosur');
    GrupoCentrado(Dom, CHAPA_MTM_ADV, 320 * 0.52, 276 * 0.885, 5, 7, 7,
      'moto-mercosur');
  end;
end;

{ ---------------------------------------------------------------------- }
{ Utilidades                                                              }
{ ---------------------------------------------------------------------- }

{ Equivale a String.replace(From, To) en JS: reemplaza SOLO la 1a ocurrencia. }
function ReplaceFirst(const S, FromStr, ToStr: String): String;
var
  P: Integer;
begin
  P := Pos(FromStr, S);
  if P > 0 then
    Result := Copy(S, 1, P - 1) + ToStr + Copy(S, P + Length(FromStr), MaxInt)
  else
    Result := S;
end;

{ Equivale a ^[A-Z] seguido de 7 digitos (con $ al final) }
function EsPatenteVieja(const S: String): Boolean;
var
  I: Integer;
begin
  Result := False;
  if Length(S) <> 8 then Exit;
  if not EsLetra(S[1]) then Exit;
  for I := 2 to 8 do
    if not EsDigito(S[I]) then Exit;
  Result := True;
end;

{ Los 5 formatos que acepta patente.valido() }
function FormatoValido(const S: String): Boolean;
var
  L: Integer;
  okLetras, okDigitos: Boolean;
begin
  Result := False;
  L := Length(S);
  if L = 8 then begin
    Result := EsPatenteVieja(S);
    Exit;
  end;
  if L = 6 then begin
    { ABC123 }
    okLetras := EsLetra(S[1]) and EsLetra(S[2]) and EsLetra(S[3]);
    okDigitos := EsDigito(S[4]) and EsDigito(S[5]) and EsDigito(S[6]);
    if okLetras and okDigitos then begin Result := True; Exit; end;
    { 123ABC }
    okDigitos := EsDigito(S[1]) and EsDigito(S[2]) and EsDigito(S[3]);
    okLetras := EsLetra(S[4]) and EsLetra(S[5]) and EsLetra(S[6]);
    if okDigitos and okLetras then begin Result := True; Exit; end;
    Exit;
  end;
  if L = 7 then begin
    { AB123CD }
    okLetras := EsLetra(S[1]) and EsLetra(S[2]);
    okDigitos := EsDigito(S[3]) and EsDigito(S[4]) and EsDigito(S[5]);
    if okLetras and okDigitos and EsLetra(S[6]) and EsLetra(S[7]) then
    begin
      Result := True;
      Exit;
    end;
    { A123BCD }
    if EsLetra(S[1]) and EsDigito(S[2]) and EsDigito(S[3]) and EsDigito(S[4]) and
       EsLetra(S[5]) and EsLetra(S[6]) and EsLetra(S[7]) then
    begin
      Result := True;
      Exit;
    end;
    Exit;
  end;
  Result := False;
end;

{ Equivale a la regex SIN ANCLAR de 9 a 11 digitos: existe alguna racha
  consecutiva de 9 o mas digitos en la cadena resultante. }
function TieneRachaDe9Digitos(const S: String): Boolean;
var
  I, Run: Integer;
begin
  Result := False;
  Run := 0;
  for I := 1 to Length(S) do begin
    if EsDigito(S[I]) then begin
      Run := Run + 1;
      if Run >= 9 then begin Result := True; Exit; end;
    end else
      Run := 0;
  end;
end;

{ Raiz digital: suma de digitos iterada hasta 1 cifra }
function RaizDigital(N: Integer): Integer;
var
  S: Integer;
begin
  while N > 9 do begin
    S := 0;
    while N > 0 do begin
      S := S + (N mod 10);
      N := N div 10;
    end;
    N := S;
  end;
  Result := N;
end;

{ ---------------------------------------------------------------------- }
{ Nucleo: replica patente.getDv() + el gate de patente.valido()           }
{ ---------------------------------------------------------------------- }

function CalcularDV(const Dominio: String; var DV: Integer; var Err: String): Boolean;
var
  Pat, Key, Code: String;
  I, X, A, B: Integer;
  Vieja: Boolean;
  Ch: Char;
begin
  Result := False;
  DV := 0;
  Err := '';

  Pat := UpperCase(Dominio);
  if Pat = '' then begin
    Err := 'Ingresá el dominio a consultar.';
    Exit;
  end;
  if not FormatoValido(Pat) then begin
    Err := 'El dominio no tiene un formato válido (6, 7 u 8 caracteres).';
    Exit;
  end;

  { Reemplazo de letras, en el MISMO orden y con la MISMA semantica (1a
    ocurrencia por llamada, 4 pasadas por letra) que el bucle for..in del JS. }
  Vieja := EsPatenteVieja(Pat);
  for I := 1 to Length(LETRAS) do begin
    Key := Copy(LETRAS, I, 1);
    if Vieja then
      Pat := ReplaceFirst(Pat, Key, '00')
    else begin
      Code := Copy(CODIGOS, (I - 1) * 2 + 1, 2);
      for X := 1 to 4 do
        Pat := ReplaceFirst(Pat, Key, Code);
    end;
  end;
  { la clave ' ' = '60' cierra el for..in del original (inalcanzable tras el
    gate de formato, pero se replica por fidelidad) }
  if Vieja then
    Pat := ReplaceFirst(Pat, ' ', '00')
  else
    for X := 1 to 4 do
      Pat := ReplaceFirst(Pat, ' ', '60');

  if not TieneRachaDe9Digitos(Pat) then begin
    Err := 'No es válida la patente ingresada.';
    Exit;
  end;

  { suma: posicion par (0-based) -> A, impar -> B }
  A := 0;
  B := 0;
  for I := 1 to Length(Pat) do begin
    Ch := Pat[I];
    if not EsDigito(Ch) then begin
      { El JS original entraria en bucle infinito aca (parseInt('A')=NaN y el
        while de raiz digital nunca termina). El sitio tampoco llega porque
        valido() corrio antes; aca se reporta error en vez de colgar. }
      Err := 'No es válida la patente ingresada.';
      Exit;
    end;
    if (I - 1) mod 2 = 0 then
      A := A + (Ord(Ch) - Ord('0'))
    else
      B := B + (Ord(Ch) - Ord('0'));
  end;

  A := RaizDigital(A);
  B := RaizDigital(B);
  DV := StrToInt(IntToStr(A) + IntToStr(B));
  Result := True;
end;

{ ---------------------------------------------------------------------- }
{ Auto-test con vectores verificados contra el patente.js exportado por REA }
{ ---------------------------------------------------------------------- }

procedure AddVector(const Dom: String; Expected: Integer; var Fail: Integer);
var
  DV: Integer;
  Err: String;
begin
  if not CalcularDV(Dom, DV, Err) then begin
    Fail := Fail + 1;
    Log('AUTOTEST FAIL ' + Dom + ': ' + Err);
  end else if DV <> Expected then begin
    Fail := Fail + 1;
    Log('AUTOTEST FAIL ' + Dom + ': obtuvo ' + IntToStr(DV) +
        ', esperaba ' + IntToStr(Expected));
  end;
end;

procedure AddInvalid(const Dom: String; var Fail: Integer);
var
  DV: Integer;
  Err: String;
begin
  if CalcularDV(Dom, DV, Err) then begin
    Fail := Fail + 1;
    Log('AUTOTEST FAIL ' + Dom + ': se esperaba error, obtuvo ' + IntToStr(DV));
  end;
end;

function AutoTest: Boolean;
var
  F: Integer;
begin
  F := 0;

  { Una por letra: cubre toda la tabla CODIGOS, no solo A-D/Q/Z. }
  AddVector('AAA999', 33, F);
  AddVector('BBB999', 93, F);
  AddVector('CCC999', 99, F);
  AddVector('DDD999', 39, F);
  AddVector('EEE999', 96, F);
  AddVector('FFF999', 69, F);
  AddVector('GGG999', 39, F);
  AddVector('HHH999', 99, F);
  AddVector('III999', 63, F);
  AddVector('JJJ999', 93, F);
  AddVector('KKK999', 63, F);
  AddVector('LLL999', 96, F);
  AddVector('MMM999', 93, F);
  AddVector('NNN999', 39, F);
  AddVector('OOO999', 66, F);
  AddVector('PPP999', 66, F);
  AddVector('QQQ999', 36, F);
  AddVector('RRR999', 39, F);
  AddVector('SSS999', 96, F);
  AddVector('TTT999', 99, F);
  AddVector('UUU999', 36, F);
  AddVector('VVV999', 69, F);
  AddVector('WWW999', 33, F);
  AddVector('XXX999', 99, F);
  AddVector('YYY999', 36, F);
  AddVector('ZZZ999', 33, F);

  { Formatos y casos de borde. }
  AddVector('QQ999QQ', 99, F);
  AddVector('AB123CD', 28, F);
  AddVector('ABC123', 57, F);
  AddVector('A1234567', 73, F);
  AddVector('B1234567', 73, F);
  AddVector('M7654321', 73, F);
  AddVector('123ABC', 93, F);
  AddVector('A123BCD', 37, F);
  AddVector('Z9876543', 69, F);
  AddVector('ZZ999AA', 17, F);
  AddVector('Z012BCD', 19, F);
  AddVector('999ZZZ', 33, F);
  AddVector('A0000000', 0, F);      { DV de un solo digito }
  AddVector('qq999qq', 99, F);      { minusculas }
  AddVector('Ab123Cd', 28, F);      { mixto }

  { Negativos: el gate de formato tiene que rechazarlos. }
  AddInvalid('', F);
  AddInvalid('A12345', F);
  AddInvalid('A123456', F);
  AddInvalid('A12345678', F);
  AddInvalid('AB1234CD', F);
  AddInvalid('ZZ0000ZZ', F);
  AddInvalid('A1A1A1A1', F);
  AddInvalid('AAAA999', F);
  AddInvalid('ABC12', F);
  AddInvalid('1234567', F);
  AddInvalid('AB123C', F);
  AddInvalid(' QQ999QQ', F);
  AddInvalid('QQ999QQ ', F);
  AddInvalid(#$00D1 + '1234567', F);

  Result := F = 0;
end;

{ ---------------------------------------------------------------------- }
{ GUI: ventana de aplicacion (TForm), nunca aparece el asistente          }
{ ---------------------------------------------------------------------- }

procedure SetEstado(const Txt: String; Modo: Integer);
{ Modo: 0 = neutro, 1 = ok, 2 = error }
begin
  if Modo = 1 then begin
    LblEstadoIcon.Caption := GLIFO_OK;
    LblEstadoIcon.Font.Color := RGB(15, 118, 110);
    LblEstado.Font.Color := RGB(15, 118, 110);
  end else if Modo = 2 then begin
    LblEstadoIcon.Caption := GLIFO_ERROR;
    LblEstadoIcon.Font.Color := RGB(190, 24, 93);
    LblEstado.Font.Color := RGB(190, 24, 93);
  end else begin
    LblEstadoIcon.Caption := '';
    LblEstado.Font.Color := RGB(71, 85, 105);
  end;
  LblEstado.Caption := Txt;
end;

procedure CalcularClick(Sender: TObject);
var
  DV, Err: String;
  N: Integer;
begin
  EdtDominio.Text := UpperCase(Trim(EdtDominio.Text));
  if CalcularDV(EdtDominio.Text, N, Err) then begin
    DV := IntToStr(N);
    EdtResultado.Text := DV;
    BtnCopiar.Enabled := True;
    SetEstado('Formato válido: copiá "' + DV + '" en el sitio de AGIP.', 1);
    MostrarChapa(EdtDominio.Text);
    AppForm.ActiveControl := EdtResultado;
    EdtResultado.SelectAll;
    HideCaret(EdtResultado.Handle);
  end else begin
    EdtResultado.Text := '';
    BtnCopiar.Enabled := False;
    OcultarChapa;
    SetEstado(Err, 2);
    AppForm.ActiveControl := EdtDominio;
  end;
end;

procedure CopiarClick(Sender: TObject);
var
  DV: String;
begin
  DV := Trim(EdtResultado.Text);
  if DV = '' then begin
    SetEstado('Todavía no hay resultado: calculá primero el dominio.', 2);
    Exit;
  end;
  if CopiarPortapapeles(DV) then
    SetEstado('Copiado al portapapeles: ' + DV, 1)
  else
    SetEstado('No se pudo copiar. Usá el valor a mano.', 2);
end;

function AbrirURL(const URL: String): Boolean;
var
  RC: Integer;
begin
  Result := ShellExec('open', URL, '', '', SW_SHOWNORMAL, ewNoWait, RC);
end;

procedure AbrirSitio(Sender: TObject);
begin
  if not AbrirURL('{#SiteURL}') then
    SetEstado('No se pudo abrir el navegador.', 2);
end;

procedure AbrirRepo(Sender: TObject);
begin
  if not AbrirURL('{#RepoURL}') then
    SetEstado('No se pudo abrir el navegador.', 2);
end;

procedure CerrarClick(Sender: TObject);
begin
  AppForm.Close;
end;

procedure CopiarDominioClick(Sender: TObject);
var
  Dom: String;
begin
  Dom := UpperCase(Trim(EdtDominio.Text));
  if Dom = '' then begin
    SetEstado('Todavía no hay dominio para copiar.', 2);
    Exit;
  end;
  if CopiarPortapapeles(Dom) then
    SetEstado('Dominio copiado: ' + Dom, 1)
  else
    SetEstado('No se pudo copiar el dominio.', 2);
end;

procedure DominioChange(Sender: TObject);
begin
  { Al editar el dominio, el DV anterior deja de ser válido. }
  if EdtResultado <> nil then
    EdtResultado.Text := '';
  if BtnCopiar <> nil then
    BtnCopiar.Enabled := False;
  OcultarChapa;
  SetEstado('Escribí el dominio y apretá Calcular.', 0);
end;

procedure LayoutApp;
var
  W, M: Integer;
begin
  W := AppForm.ClientWidth;
  M := Sc(14);   { margen de seguridad: nada toca los bordes }

  { franja de acento: a sangre, es un elemento de diseno }
  Acento.Left := 0;
  Acento.Top := 0;
  Acento.Width := W;
  Acento.Height := Sc(4);

  LblSec1.Left := M;
  LblSec1.Top := Sc(18);

  EdtDominio.Left := M;
  EdtDominio.Top := Sc(36);
  EdtDominio.Width := Sc(230);
  EdtDominio.Height := Sc(30);

  LblCopiarDom.Left := M + Sc(238);
  LblCopiarDom.Top := Sc(44);

  BtnCalcular.Left := M + Sc(266);
  BtnCalcular.Top := Sc(36);
  BtnCalcular.Width := Sc(140);
  BtnCalcular.Height := Sc(30);

  IconoApp.Left := W - M - Sc(56);
  IconoApp.Top := Sc(14);
  IconoApp.Width := Sc(56);
  IconoApp.Height := Sc(56);

  LblSec2.Left := M;
  LblSec2.Top := Sc(106);

  EdtResultado.Left := M;
  EdtResultado.Top := Sc(124);
  EdtResultado.Width := Sc(210);
  EdtResultado.Height := Sc(52);

  BtnCopiar.Left := M + Sc(218);
  BtnCopiar.Top := Sc(134);
  BtnCopiar.Width := Sc(150);
  BtnCopiar.Height := Sc(32);

  LblEstadoIcon.Left := M;
  LblEstadoIcon.Top := Sc(75);

  LblEstado.Left := M + Sc(24);
  LblEstado.Top := Sc(72);
  LblEstado.Width := W - 2 * M - Sc(24);
  LblEstado.Height := Sc(28);

  LblChapa.Left := M;
  LblChapa.Top := Sc(184);

  { la chapa misma la posiciona MostrarChapa segun el estilo: ocupa un
    recuadro de ClientWidth-2*M x Sc(CHAPA_BOX_ALTO) desde Sc(200) }

  LblSec3.Left := M;
  LblSec3.Top := Sc(365);

  LblLinkIcon.Left := M;
  LblLinkIcon.Top := Sc(384);

  LblLink.Left := M + Sc(24);
  LblLink.Top := Sc(382);
  LblLink.Width := W - 2 * M - Sc(24);
  LblLink.Height := Sc(20);

  LblAyuda.Left := M;
  LblAyuda.Top := Sc(409);
  LblAyuda.Width := W - 2 * M;
  LblAyuda.Height := Sc(36);

  LblAviso.Left := M;
  LblAviso.Top := Sc(453);
  LblAviso.Width := W - 2 * M - Sc(100);
  LblAviso.Height := Sc(36);

  LblAutorIcon.Left := M;
  LblAutorIcon.Top := Sc(498);

  LblAutor.Left := M + Sc(24);
  LblAutor.Top := Sc(496);
  LblAutor.Width := W - 2 * M - Sc(24) - Sc(100);
  LblAutor.Height := Sc(20);

  BtnCerrar.Left := W - M - Sc(90);
  BtnCerrar.Top := Sc(491);
  BtnCerrar.Width := Sc(90);
  BtnCerrar.Height := Sc(26);
end;

procedure ConstruirUI;
begin
  AppForm := TForm.Create(nil);

  AppForm.Position := poScreenCenter;
  AppForm.BorderStyle := bsDialog;
  AppForm.Caption := '{#AppName}';
  AppForm.Font.Name := 'Segoe UI';
  AppForm.Font.Size := 9;

  Dpi := GetDpiForWindow(AppForm.Handle);
  if Dpi <= 0 then Dpi := 96;

  AppForm.ClientWidth := Sc(500);
  AppForm.ClientHeight := Sc(531);

  ExtractTemporaryFile('preview-64.png');
  ExtractTemporaryFile('accent-teal.png');

  Acento := TBitmapImage.Create(AppForm);
  Acento.Parent := AppForm;
  Acento.PngImage.LoadFromFile(ExpandConstant('{tmp}\accent-teal.png'));
  Acento.Stretch := True;
  Acento.BackColor := clNone;

  IconoApp := TBitmapImage.Create(AppForm);
  IconoApp.Parent := AppForm;
  IconoApp.PngImage.LoadFromFile(ExpandConstant('{tmp}\preview-64.png'));
  IconoApp.Stretch := True;
  IconoApp.BackColor := clNone;

  { chapa del dominio: 1 fondo + 8 slots de glifos; el orden de creacion
    fija el z-order (el fondo queda debajo de los tiles) }
  ChapaExtraidos := TStringList.Create;

  ChapaBg := TBitmapImage.Create(AppForm);
  ChapaBg.Parent := AppForm;
  ChapaBg.Stretch := True;
  ChapaBg.BackColor := clNone;
  ChapaBg.Visible := False;

  ChapaG1 := TBitmapImage.Create(AppForm);
  ChapaG1.Parent := AppForm;
  ChapaG1.Stretch := True;
  ChapaG1.BackColor := clNone;
  ChapaG1.Visible := False;

  ChapaG2 := TBitmapImage.Create(AppForm);
  ChapaG2.Parent := AppForm;
  ChapaG2.Stretch := True;
  ChapaG2.BackColor := clNone;
  ChapaG2.Visible := False;

  ChapaG3 := TBitmapImage.Create(AppForm);
  ChapaG3.Parent := AppForm;
  ChapaG3.Stretch := True;
  ChapaG3.BackColor := clNone;
  ChapaG3.Visible := False;

  ChapaG4 := TBitmapImage.Create(AppForm);
  ChapaG4.Parent := AppForm;
  ChapaG4.Stretch := True;
  ChapaG4.BackColor := clNone;
  ChapaG4.Visible := False;

  ChapaG5 := TBitmapImage.Create(AppForm);
  ChapaG5.Parent := AppForm;
  ChapaG5.Stretch := True;
  ChapaG5.BackColor := clNone;
  ChapaG5.Visible := False;

  ChapaG6 := TBitmapImage.Create(AppForm);
  ChapaG6.Parent := AppForm;
  ChapaG6.Stretch := True;
  ChapaG6.BackColor := clNone;
  ChapaG6.Visible := False;

  ChapaG7 := TBitmapImage.Create(AppForm);
  ChapaG7.Parent := AppForm;
  ChapaG7.Stretch := True;
  ChapaG7.BackColor := clNone;
  ChapaG7.Visible := False;

  ChapaG8 := TBitmapImage.Create(AppForm);
  ChapaG8.Parent := AppForm;
  ChapaG8.Stretch := True;
  ChapaG8.BackColor := clNone;
  ChapaG8.Visible := False;

  LblSec1 := TNewStaticText.Create(AppForm);
  LblSec1.Parent := AppForm;
  LblSec1.Caption := 'DOMINIO (PATENTE)';
  LblSec1.Font.Size := 8;
  LblSec1.Font.Style := [fsBold];
  LblSec1.Font.Color := RGB(15, 118, 110);

  EdtDominio := TNewEdit.Create(AppForm);
  EdtDominio.Parent := AppForm;
  EdtDominio.MaxLength := 16;
  EdtDominio.Font.Size := 10;
  EdtDominio.Text := '';

  BtnCalcular := TNewButton.Create(AppForm);
  BtnCalcular.Parent := AppForm;
  BtnCalcular.Caption := 'Calcular';
  BtnCalcular.Font.Size := 10;
  BtnCalcular.Font.Style := [fsBold];
  BtnCalcular.Default := True;
  BtnCalcular.OnClick := @CalcularClick;

  LblCopiarDom := TNewStaticText.Create(AppForm);
  LblCopiarDom.Parent := AppForm;
  LblCopiarDom.Caption := GLIFO_COPIAR;   { icono de copiar }
  LblCopiarDom.Font.Name := 'Segoe MDL2 Assets';
  LblCopiarDom.Font.Size := 11;
  LblCopiarDom.Font.Color := RGB(71, 85, 105);
  LblCopiarDom.AutoSize := True;
  LblCopiarDom.Cursor := crHand;
  LblCopiarDom.Hint := 'Copiar dominio';
  LblCopiarDom.ShowHint := True;
  LblCopiarDom.OnClick := @CopiarDominioClick;

  LblSec2 := TNewStaticText.Create(AppForm);
  LblSec2.Parent := AppForm;
  LblSec2.Caption := 'DÍGITO VERIFICADOR';
  LblSec2.Font.Size := 8;
  LblSec2.Font.Style := [fsBold];
  LblSec2.Font.Color := RGB(15, 118, 110);

  LblChapa := TNewStaticText.Create(AppForm);
  LblChapa.Parent := AppForm;
  LblChapa.Caption := 'CHAPA DEL DOMINIO';
  LblChapa.Font.Size := 8;
  LblChapa.Font.Style := [fsBold];
  LblChapa.Font.Color := RGB(15, 118, 110);

  EdtResultado := TNewEdit.Create(AppForm);
  EdtResultado.Parent := AppForm;
  EdtResultado.ReadOnly := True;
  SetWindowLong(EdtResultado.Handle, GWL_STYLE,
    GetWindowLong(EdtResultado.Handle, GWL_STYLE) or ES_CENTER);
  EdtResultado.Font.Name := 'Segoe UI';
  EdtResultado.Font.Size := 26;
  EdtResultado.Font.Style := [fsBold];
  EdtResultado.Font.Color := RGB(15, 118, 110);
  EdtResultado.Color := RGB(240, 253, 250);
  EdtResultado.Text := '';

  BtnCopiar := TNewButton.Create(AppForm);
  BtnCopiar.Parent := AppForm;
  BtnCopiar.Caption := 'Copiar resultado';
  BtnCopiar.Enabled := False;
  BtnCopiar.OnClick := @CopiarClick;

  LblEstadoIcon := TNewStaticText.Create(AppForm);
  LblEstadoIcon.Parent := AppForm;
  LblEstadoIcon.Font.Name := 'Segoe MDL2 Assets';
  LblEstadoIcon.Font.Size := 11;
  LblEstadoIcon.AutoSize := True;

  LblEstado := TNewStaticText.Create(AppForm);
  LblEstado.Parent := AppForm;
  LblEstado.AutoSize := False;
  LblEstado.WordWrap := True;
  LblEstado.Font.Size := 9;

  LblSec3 := TNewStaticText.Create(AppForm);
  LblSec3.Parent := AppForm;
  LblSec3.Caption := 'CÓMO USARLO EN EL SITIO';
  LblSec3.Font.Size := 8;
  LblSec3.Font.Style := [fsBold];
  LblSec3.Font.Color := RGB(15, 118, 110);

  LblLinkIcon := TNewStaticText.Create(AppForm);
  LblLinkIcon.Parent := AppForm;
  LblLinkIcon.Caption := GLIFO_ABRIR;
  LblLinkIcon.Font.Name := 'Segoe MDL2 Assets';
  LblLinkIcon.Font.Size := 11;
  LblLinkIcon.Font.Color := RGB(15, 118, 110);
  LblLinkIcon.Cursor := crHandPoint;
  LblLinkIcon.Hint := 'Abrir el sitio de AGIP (lb.agip.gob.ar/ConsultaPat/)';
  LblLinkIcon.ShowHint := True;
  LblLinkIcon.OnClick := @AbrirSitio;

  LblLink := TNewStaticText.Create(AppForm);
  LblLink.Parent := AppForm;
  LblLink.Caption := 'Abrir sitio de AGIP';
  LblLink.Font.Size := 9;
  LblLink.Font.Style := [fsBold, fsUnderline];
  LblLink.Font.Color := RGB(15, 118, 110);
  LblLink.Cursor := crHandPoint;
  LblLink.Hint := 'Abrir el sitio de AGIP (lb.agip.gob.ar/ConsultaPat/)';
  LblLink.ShowHint := True;
  LblLink.OnClick := @AbrirSitio;

  LblAyuda := TNewStaticText.Create(AppForm);
  LblAyuda.Parent := AppForm;
  LblAyuda.AutoSize := False;
  LblAyuda.WordWrap := True;
  LblAyuda.Font.Size := 9;
  LblAyuda.Font.Color := RGB(71, 85, 105);
  LblAyuda.Caption := 'En el sitio, marcá "Cuento con el dígito verificador" ' +
    'y pegá el DV.' + #13#10 + 'Si te pide el dominio de nuevo, destildá la casilla.';

  LblAviso := TNewStaticText.Create(AppForm);
  LblAviso.Parent := AppForm;
  LblAviso.AutoSize := False;
  LblAviso.WordWrap := True;
  LblAviso.Font.Size := 9;
  LblAviso.Font.Color := RGB(71, 85, 105);
  LblAviso.Caption := 'No oficial, sin afiliación con AGIP. Cálculo local. ' +
    'El DV es informativo; usalo con fines lícitos.';

  LblAutorIcon := TNewStaticText.Create(AppForm);
  LblAutorIcon.Parent := AppForm;
  LblAutorIcon.Caption := GLIFO_LINK;
  LblAutorIcon.Font.Name := 'Segoe MDL2 Assets';
  LblAutorIcon.Font.Size := 11;
  LblAutorIcon.Font.Color := RGB(15, 118, 110);
  LblAutorIcon.AutoSize := True;
  LblAutorIcon.Cursor := crHandPoint;
  LblAutorIcon.Hint := 'Abrir el repositorio en GitHub';
  LblAutorIcon.ShowHint := True;
  LblAutorIcon.OnClick := @AbrirRepo;

  LblAutor := TNewStaticText.Create(AppForm);
  LblAutor.Parent := AppForm;
  LblAutor.Caption := 'Hecho por {#Autor} · github.com/{#Autor}/DV';
  LblAutor.Font.Size := 9;
  LblAutor.Font.Style := [fsBold, fsUnderline];
  LblAutor.Font.Color := RGB(15, 118, 110);
  LblAutor.Cursor := crHandPoint;
  LblAutor.Hint := 'Abrir el repositorio en GitHub';
  LblAutor.ShowHint := True;
  LblAutor.OnClick := @AbrirRepo;

  BtnCerrar := TNewButton.Create(AppForm);
  BtnCerrar.Parent := AppForm;
  BtnCerrar.Caption := 'Cerrar';
  BtnCerrar.Cancel := True;
  BtnCerrar.OnClick := @CerrarClick;

  SetEstado('Ingresá el dominio y apretá Calcular. Ej: AB123CD.', 0);

  EdtDominio.OnChange := @DominioChange;
  AppForm.ActiveControl := EdtDominio;

  LayoutApp;
end;

{ ---------------------------------------------------------------------- }
{ Arranque                                                                }
{ ---------------------------------------------------------------------- }

function EsModoArchivo: Boolean;
begin
  Result := (ParamCount() >= 2) and
    (CompareText(ParamStr(1), '--copy') <> 0) and
    (Copy(ParamStr(2), 1, 1) <> '/');
end;

function InitializeSetup(): Boolean;
var
  Dom, OutFile, Line: String;
  DV: Integer;
  Err: String;
  Prefill: String;
begin
  { Por defecto: nunca se muestra el asistente de Inno. }
  Result := False;

  Log('ARRANQUE argc=' + IntToStr(ParamCount()));

  { dv-caba-portable.exe --copy TEXTO : copia y sale }
  if (ParamCount() >= 2) and (CompareText(ParamStr(1), '--copy') = 0) then begin
    if CopiarPortapapeles(ParamStr(2)) then
      ExitProcess(0)
    else
      ExitProcess(2);
    Exit;
  end;

  { El autotest corre tambien antes del modo archivo. En modo silencioso
    no mostramos un dialogo: el codigo de salida 2 es suficiente. }
  if not AutoTest then begin
    Log('AUTOTEST FAIL: la aplicacion no se puede usar.');
    if EsModoArchivo then
      ExitProcess(2);
    MsgBox('Fallo el autotest del algoritmo. La aplicacion no se puede usar.',
      mbError, MB_OK);
    ExitProcess(2);
  end;

  { dv-caba-portable.exe DOMINIO [archivo-salida] : escribe el resultado y sale.
    Un conmutador (empieza con "/") nunca se toma como archivo de salida. }
  if EsModoArchivo then begin
    Dom := ParamStr(1);
    OutFile := ParamStr(2);
    if CalcularDV(Dom, DV, Err) then begin
      Line := 'DV=' + IntToStr(DV);
      if not SaveStringToFile(OutFile, Line + #13#10, False) then begin
        Log('ERROR: no se pudo escribir ' + OutFile);
        ExitProcess(2);
      end;
      ExitProcess(0);
    end else begin
      Line := 'ERROR=' + Err;
      if not SaveStringToFile(OutFile, Line + #13#10, False) then
        Log('ERROR: no se pudo escribir ' + OutFile);
      ExitProcess(2);
    end;
    Exit;
  end;

  { Modo grafico }
  ConstruirUI;

  Prefill := '';
  if (ParamCount() >= 1) and (Copy(ParamStr(1), 1, 1) <> '/') then
    Prefill := ParamStr(1);
  if Prefill <> '' then begin
    EdtDominio.Text := UpperCase(Prefill);
    CalcularClick(EdtDominio);
  end;

  AppForm.ShowModal;
  AppForm.Free;
  AppForm := nil;

  DelTree(ExpandConstant('{tmp}'), True, True, True);
  ExitProcess(0);
end;
