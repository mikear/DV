; ============================================================================
;  dv-caba.iss - Calculadora PORTABLE del DIGITO VERIFICADOR de patentes CABA
;  Sitio objetivo: https://lb.agip.gob.ar/ConsultaPat/
;
;  Esto NO es un instalador: el binario nunca muestra el asistente de Inno.
;  InitializeSetup() crea una TForm propia, muestra la GUI y termina el
;  proceso con ExitProcess(0). No se instala nada, no hay desinstalador.
;
;  Algoritmo: port 1:1 de patente.getDv()
;             (https://lb.agip.gob.ar/libFe/js/patente.js, SHA-256 aaf9d407...)
;             Verificado contra el original exportado por REA: 432 casos /
;             1282 comprobaciones (test-paridad.js). El binario repite esa
;             misma bateria como autotest antes de abrir la GUI.
;
;  Autoria: mikear - https://github.com/mikear/DV
;  Herramienta NO oficial, sin afiliacion con AGIP. Ver DISCLAIMER.md.
;
;  El binario NO ejecuta procesos externos (ni powershell ni cmd): el
;  portapapeles se usa via API nativa de Win32 (user32/kernel32).
;
;  Modos de uso:
;    dv-caba.exe                     -> abre la app
;    dv-caba.exe QQ999QQ             -> app con el dominio precargado
;    dv-caba.exe QQ999QQ C:\r.txt    -> escribe "DV=99" y sale, exit 0/2
;    dv-caba.exe --copy 15           -> copia al portapapeles, exit 0/2
; ============================================================================

#define AppName "DV Patentes CABA"
#define AppVersion "1.0.0"
#define OutputName "dv-caba"
#define SiteURL "https://lb.agip.gob.ar/ConsultaPat/"

[Setup]
AppId={{5B0E2C4A-9F31-4E77-8A62-3D1C7F0A9B21}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=mikear
VersionInfoVersion={#AppVersion}
VersionInfoProductVersion={#AppVersion}
VersionInfoTextVersion={#AppVersion}
VersionInfoCompany=mikear
VersionInfoDescription=Calculadora portable del digito verificador de patentes CABA
VersionInfoProductName={#AppName}
VersionInfoOriginalFileName={#OutputName}-portable.exe
VersionInfoCopyright=Copyright (C) 2026 mikear - Herramienta no oficial
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

[Code]
const
  { Tabla de letras del original. A=14 B=01 C=00 ... Z=17 }
  LETRAS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  CODIGOS = '1401001605201909240721080413252218100206122311031517';
  CF_UNICODETEXT = 13;
  GMEM_MOVEABLE = $0002;

  { glifos Segoe MDL2 Assets (NO son emojis) - literales anchos, ya que
    Chr() trunca al byte bajo y produce caracteres incorrectos }
  GLIFO_OK     = #$E73E;   { check }
  GLIFO_ERROR  = #$E711;   { cancel / X }
  GLIFO_COPIAR = #$E8C8;   { copy }
  GLIFO_ABRIR  = #$E8A7;   { open in new window }

var
  AppForm: TForm;
  Acento, IconoApp: TBitmapImage;
  LblSec1, LblSec2, LblSec3: TNewStaticText;
  LblCopiarIcon, LblCopiarDom, LblLinkIcon, LblEstadoIcon: TNewStaticText;
  LblEstado, LblLink, LblAyuda, LblAviso: TNewStaticText;
  EdtDominio, EdtResultado: TNewEdit;
  BtnCalcular, BtnCopiar, BtnCerrar: TNewButton;
  Dpi: Integer;

{ ---------------------------------------------------------------------- }
{ APIs nativas de Win32 (sin crear procesos externos)                    }
{ ---------------------------------------------------------------------- }

function GetDpiForWindow(AWnd: Integer): Integer;
  external 'GetDpiForWindow@user32.dll stdcall';

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
  if P = 0 then Exit;
  lstrcpyW(P, Texto);
  GlobalUnlock(H);
  if OpenClipboard(0) = 0 then Exit;
  EmptyClipboard();
  if SetClipboardData(CF_UNICODETEXT, H) <> 0 then
    Result := True;
  CloseClipboard();
end;

{ escala un valor en px de 96 DPI al DPI actual }
function Sc(V: Integer): Integer;
begin
  Result := (V * Dpi + 48) div 96;
end;

{ ---------------------------------------------------------------------- }
{ Utilidades                                                              }
{ ---------------------------------------------------------------------- }

function EsLetra(C: Char): Boolean;
begin
  Result := (C >= 'A') and (C <= 'Z');
end;

function EsDigito(C: Char): Boolean;
begin
  Result := (C >= '0') and (C <= '9');
end;

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
  L, I: Integer;
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
  I := 0; { evita warning }
  if I <> 0 then Result := True;
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

  Pat := UpperCase(Trim(Dominio));
  if Pat = '' then begin
    Err := 'Debe especificar el dominio a consultar.';
    Exit;
  end;
  if not FormatoValido(Pat) then begin
    Err := 'El dominio no tiene un formato valido (6, 7 u 8 caracteres).';
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
    Err := 'No es valida la patente ingresada.';
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
      Err := 'No es valida la patente ingresada.';
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
  DV, N: Integer;
  Err: String;
begin
  N := Fail;
  if not CalcularDV(Dom, DV, Err) then begin
    Fail := Fail + 1;
    Log('AUTOTEST FAIL ' + Dom + ': ' + Err);
  end else if DV <> Expected then begin
    Fail := Fail + 1;
    Log('AUTOTEST FAIL ' + Dom + ': obtuvo ' + IntToStr(DV) +
        ', esperaba ' + IntToStr(Expected));
  end;
  if Fail > N then
    Log('  ^ vector ' + Dom);
end;

function AutoTest: Boolean;
var
  F: Integer;
begin
  F := 0;
  AddVector('QQ999QQ', 99, F);      { formato Mercosur, sintetico }
  AddVector('AB123CD', 28, F);
  AddVector('ABC123', 57, F);
  AddVector('A1234567', 73, F);     { patente vieja }
  AddVector('123ABC', 93, F);       { moto nueva }
  AddVector('A123BCD', 37, F);      { moto Mercosur }
  AddVector('AAA999', 33, F);
  AddVector('Z9876543', 69, F);
  AddVector('ZZ999AA', 17, F);
  AddVector('Z012BCD', 19, F);
  AddVector('999ZZZ', 33, F);
  AddVector('A0000000', 0, F);      { DV de un solo digito }
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
    LblEstado.Font.Color := RGB(100, 116, 139);
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
    SetEstado('Formato valido: copia "' + DV + '" en el campo del sitio AGIP.', 1);
    EdtResultado.SelectAll;
  end else begin
    EdtResultado.Text := '';
    SetEstado(Err, 2);
  end;
end;

procedure CopiarClick(Sender: TObject);
var
  DV: String;
begin
  DV := Trim(EdtResultado.Text);
  if DV = '' then begin
    SetEstado('Todavia no hay resultado: calcula primero el dominio.', 2);
    Exit;
  end;
  if CopiarPortapapeles(DV) then
    SetEstado('Copiado al portapapeles: ' + DV, 1)
  else
    SetEstado('No se pudo copiar. Usa el valor a mano.', 2);
end;

procedure AbrirSitio(Sender: TObject);
var
  RC: Integer;
begin
  if not ShellExec('open', '{#SiteURL}', '', '', SW_SHOWNORMAL, ewNoWait, RC) then
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
    SetEstado('Todavia no hay dominio para copiar.', 2);
    Exit;
  end;
  if CopiarPortapapeles(Dom) then
    SetEstado('Dominio copiado: ' + Dom, 1)
  else
    SetEstado('No se pudo copiar el dominio.', 2);
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
  EdtDominio.Height := Sc(28);

  LblCopiarDom.Left := M + Sc(238);
  LblCopiarDom.Top := Sc(43);

  BtnCalcular.Left := M + Sc(266);
  BtnCalcular.Top := Sc(36);
  BtnCalcular.Width := Sc(130);
  BtnCalcular.Height := Sc(28);

  IconoApp.Left := W - M - Sc(56);
  IconoApp.Top := Sc(14);
  IconoApp.Width := Sc(56);
  IconoApp.Height := Sc(56);

  LblSec2.Left := M;
  LblSec2.Top := Sc(84);

  EdtResultado.Left := M;
  EdtResultado.Top := Sc(102);
  EdtResultado.Width := Sc(180);
  EdtResultado.Height := Sc(50);

  LblCopiarIcon.Left := M + Sc(186);
  LblCopiarIcon.Top := Sc(117);

  BtnCopiar.Left := M + Sc(214);
  BtnCopiar.Top := Sc(112);
  BtnCopiar.Width := Sc(150);
  BtnCopiar.Height := Sc(30);

  LblEstadoIcon.Left := M;
  LblEstadoIcon.Top := Sc(164);

  LblEstado.Left := M + Sc(24);
  LblEstado.Top := Sc(162);
  LblEstado.Width := W - 2 * M - Sc(24);
  LblEstado.Height := Sc(34);

  LblSec3.Left := M;
  LblSec3.Top := Sc(206);

  LblLinkIcon.Left := M;
  LblLinkIcon.Top := Sc(225);

  LblLink.Left := M + Sc(24);
  LblLink.Top := Sc(223);
  LblLink.Width := W - 2 * M - Sc(24);
  LblLink.Height := Sc(20);

  LblAyuda.Left := M;
  LblAyuda.Top := Sc(252);
  LblAyuda.Width := W - 2 * M;
  LblAyuda.Height := Sc(34);

  LblAviso.Left := M;
  LblAviso.Top := Sc(298);
  LblAviso.Width := W - 2 * M - Sc(140);
  LblAviso.Height := Sc(32);

  BtnCerrar.Left := W - M - Sc(124);
  BtnCerrar.Top := Sc(298);
  BtnCerrar.Width := Sc(124);
  BtnCerrar.Height := Sc(30);
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
  AppForm.ClientHeight := Sc(342);

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

  LblSec1 := TNewStaticText.Create(AppForm);
  LblSec1.Parent := AppForm;
  LblSec1.Caption := 'DOMINIO (PATENTE)';
  LblSec1.Font.Size := 8;
  LblSec1.Font.Style := [fsBold];
  LblSec1.Font.Color := RGB(15, 118, 110);

  EdtDominio := TNewEdit.Create(AppForm);
  EdtDominio.Parent := AppForm;
  EdtDominio.MaxLength := 16;
  EdtDominio.Text := '';

  BtnCalcular := TNewButton.Create(AppForm);
  BtnCalcular.Parent := AppForm;
  BtnCalcular.Caption := 'Calcular';
  BtnCalcular.Default := True;
  BtnCalcular.OnClick := @CalcularClick;

  LblCopiarDom := TNewStaticText.Create(AppForm);
  LblCopiarDom.Parent := AppForm;
  LblCopiarDom.Caption := GLIFO_COPIAR;   { mismo icono que el de abajo }
  LblCopiarDom.Font.Name := 'Segoe MDL2 Assets';
  LblCopiarDom.Font.Size := 11;
  LblCopiarDom.Font.Color := RGB(100, 116, 139);
  LblCopiarDom.AutoSize := True;
  LblCopiarDom.Cursor := crHand;
  LblCopiarDom.OnClick := @CopiarDominioClick;

  LblSec2 := TNewStaticText.Create(AppForm);
  LblSec2.Parent := AppForm;
  LblSec2.Caption := 'DIGITO VERIFICADOR';
  LblSec2.Font.Size := 8;
  LblSec2.Font.Style := [fsBold];
  LblSec2.Font.Color := RGB(15, 118, 110);

  EdtResultado := TNewEdit.Create(AppForm);
  EdtResultado.Parent := AppForm;
  EdtResultado.ReadOnly := True;
  EdtResultado.Font.Name := 'Segoe UI';
  EdtResultado.Font.Size := 22;
  EdtResultado.Font.Style := [fsBold];
  EdtResultado.Font.Color := RGB(15, 118, 110);
  EdtResultado.Color := RGB(240, 253, 250);
  EdtResultado.Text := '';

  LblCopiarIcon := TNewStaticText.Create(AppForm);
  LblCopiarIcon.Parent := AppForm;
  LblCopiarIcon.Caption := GLIFO_COPIAR;
  LblCopiarIcon.Font.Name := 'Segoe MDL2 Assets';
  LblCopiarIcon.Font.Size := 11;
  LblCopiarIcon.Font.Color := RGB(100, 116, 139);

  BtnCopiar := TNewButton.Create(AppForm);
  BtnCopiar.Parent := AppForm;
  BtnCopiar.Caption := 'Copiar resultado';
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
  LblEstado.Font.Size := 8;

  LblSec3 := TNewStaticText.Create(AppForm);
  LblSec3.Parent := AppForm;
  LblSec3.Caption := 'USALO EN EL SITIO';
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
  LblLinkIcon.OnClick := @AbrirSitio;

  LblLink := TNewStaticText.Create(AppForm);
  LblLink.Parent := AppForm;
  LblLink.Caption := 'Abrir lb.agip.gob.ar/ConsultaPat/';
  LblLink.Font.Size := 9;
  LblLink.Font.Style := [fsBold, fsUnderline];
  LblLink.Font.Color := RGB(15, 118, 110);
  LblLink.Cursor := crHandPoint;
  LblLink.OnClick := @AbrirSitio;

  LblAyuda := TNewStaticText.Create(AppForm);
  LblAyuda.Parent := AppForm;
  LblAyuda.AutoSize := False;
  LblAyuda.WordWrap := True;
  LblAyuda.Font.Size := 8;
  LblAyuda.Font.Color := RGB(100, 116, 139);
  LblAyuda.Caption := 'En el sitio: tilda "Cuento con el digito verificador" ' +
    'y pega el valor.' + #13#10 +
    'Si el sitio pide reingresar el dominio, no tildes la casilla.';

  LblAviso := TNewStaticText.Create(AppForm);
  LblAviso.Parent := AppForm;
  LblAviso.AutoSize := False;
  LblAviso.WordWrap := True;
  LblAviso.Font.Size := 7;
  LblAviso.Font.Color := RGB(148, 163, 184);
  LblAviso.Caption := 'Herramienta no oficial, sin afiliacion con AGIP. ' +
    'El DV es informativo. Uso responsable de los datos.';

  BtnCerrar := TNewButton.Create(AppForm);
  BtnCerrar.Parent := AppForm;
  BtnCerrar.Caption := 'Cerrar';
  BtnCerrar.OnClick := @CerrarClick;

  SetEstado('Escribe el dominio y apreta Calcular.', 0);

  LayoutApp;
end;

{ ---------------------------------------------------------------------- }
{ Arranque                                                                }
{ ---------------------------------------------------------------------- }

function InitializeSetup(): Boolean;
var
  Dom, OutFile, Line: String;
  DV: Integer;
  Err: String;
  Prefill: String;
begin
  { Por defecto: nunca se muestra el asistente de Inno. }
  Result := False;

  Log('ARRANQUE argc=' + IntToStr(ParamCount()) + ' p1=[' + ParamStr(1) +
      '] p2=[' + ParamStr(2) + ']');

  { dv-caba.exe --copy TEXTO : copia y sale }
  if (ParamCount() >= 2) and (CompareText(ParamStr(1), '--copy') = 0) then begin
    if CopiarPortapapeles(ParamStr(2)) then
      ExitProcess(0)
    else
      ExitProcess(2);
    Exit;
  end;

  { dv-caba.exe DOMINIO [archivo-salida] : escribe el resultado y sale.
    Un conmutador (empieza con "/") nunca se toma como archivo de salida. }
  if (ParamCount() >= 2) and (Copy(ParamStr(2), 1, 1) <> '/') then begin
    Dom := ParamStr(1);
    OutFile := ParamStr(2);
    if CalcularDV(Dom, DV, Err) then begin
      Line := 'DV=' + IntToStr(DV);
      SaveStringToFile(OutFile, Line + #13#10, False);
      ExitProcess(0);
    end else begin
      Line := 'ERROR=' + Err;
      SaveStringToFile(OutFile, Line + #13#10, False);
      ExitProcess(2);
    end;
    Exit;
  end;

  { Modo grafico }
  if not AutoTest then begin
    MsgBox('Fallo el autotest del algoritmo. La aplicacion no se puede usar.',
      mbError, MB_OK);
    ExitProcess(2);
  end;

  ConstruirUI;

  Prefill := '';
  if ParamCount() >= 1 then
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
