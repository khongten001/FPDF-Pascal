{

 FPDF Pascal Extensions
 https://github.com/Projeto-ACBr-Oficial/FPDF-Pascal

 Copyright (C) 2023 Projeto ACBr - Daniel Simões de Almeida

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 of the Software, and to permit persons to whom the Software is furnished to do
 so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

 Except as contained in this notice, the name of <Projeto ACBr> shall not be
 used in advertising or otherwise to promote the sale, use or other dealings in
 this Software without prior written authorization from <Projeto ACBr>.

 Based on:
 - The FPDF Scripts
   http://www.fpdf.org/en/script/index.php
 - Free JPDF Pascal from Jean Patrick e Gilson Nunes
   https://github.com/jepafi/Free-JPDF-Pascal
}

unit fpdf_ext;

// Define USESYNAPSE if you want to force use of synapse
{.$DEFINE USESYNAPSE}

// If you don't want the AnsiString vs String warnings to bother you
{.$DEFINE REMOVE_CAST_WARN}

{$IfNDef FPC}
  {$Define USESYNAPSE}

  {$IFDEF REMOVE_CAST_WARN}
    {$WARN IMPLICIT_STRING_CAST OFF}
    {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
  {$ENDIF}
{$EndIf}

{$IfDef FPC}
  {$Mode objfpc}{$H+}
  {$Define USE_UTF8}
{$EndIf}

{$IfDef POSIX}
  {$IfDef LINUX}
    {$Define USE_UTF8}
  {$EndIf}
  {$Define FMX}
{$EndIf}

{$IfDef NEXTGEN}
  {$ZEROBASEDSTRINGS OFF}
  {$Define USE_UTF8}
{$EndIf}

interface

uses
  Classes, SysUtils,
  fpdf,
  {$IFDEF USESYNAPSE}
  httpsend, ssl_openssl
  {$ELSE}
   fphttpclient, opensslsockets
  {$ENDIF};

{$IfDef NEXTGEN}
type
  AnsiString = RawByteString;
  AnsiChar = UTF8Char;
  PAnsiChar = MarshaledAString;
  PPAnsiChar = ^MarshaledAString;
  WideString = String;
{$EndIf}

const
  cDefBarHeight = 8;
  cDefBarWidth = 0.5; //0.35;

type

  TFPDFExt = class;

  { TFPDFScripts }

  TFPDFScripts = class
  protected
    fpFPDF: TFPDFExt;
  public
    constructor Create(AFPDF: TFPDFExt); virtual;
  end;


  { TFPDFScriptCodeEAN }

  TFPDFScriptCodeEAN = class(TFPDFScripts)
  private
    procedure CheckBarCode(var ABarCode: string; BarCodeLen: integer;
      const BarCodeName: string);
    function AdjustBarCodeSize(const ABarCode: string; BarCodeLen: integer): string;
    function CalcBinCode(const ABarCode: string): String;
    procedure DrawBarcode(const BinCode: string; vX: double; vY: double;
      BarHeight: double = 0; BarWidth: double = 0);
    function GetCheckDigit(const ABarCode: string; const BarCodeName: string): integer;
    function TestCheckDigit(const ABarCode: string; const BarCodeName: string): boolean;
  public
    procedure CodeEAN13(const ABarCode: string; vX: double; vY: double;
      BarHeight: double = 0; BarWidth: double = 0);
    procedure CodeEAN8(const ABarCode: string; vX: double; vY: double;
      BarHeight: double = 0; BarWidth: double = 0);
  end;

  { TFPDFScriptCode39 }

  TFPDFScriptCode39 = class(TFPDFScripts)
  private
  public
    procedure Code39(const ABarCode: string; vX: double; vY: double;
      BarHeight: double = 0; BarWidth: double = 0);
  end;

  { TFPDFScriptCode128 }

  TCode128 = (code128A, code128B, code128C);
  TFPDFScriptCode128 = class(TFPDFScripts)
  private
  public
    constructor Create(AFPDF: TFPDFExt); override;
    procedure Code128(const ABarCode: string; vX: double; vY: double;
      BarHeight: double = 0; BarWidth: double = 0);
  end;

  { TFPDFExt }

  TFPDFExt = class(TFPDF)
  private
    fProxyHost: string;
    fProxyPass: string;
    fProxyPort: string;
    fProxyUser: string;

    procedure GetImageFromURL(const aURL: string; const aResponse: TStream);
  protected

  public
    procedure InternalCreate; override;

    procedure Image(const vFileOrURL: string; vX: double = -9999;
      vY: double = -9999; vWidth: double = 0; vHeight: double = 0;
      const vLink: string = ''); overload; override;
    procedure CodeEAN13(const ABarCode: string; vX: double; vY: double;
      BarHeight: double = 0; BarWidth: double = 0);
    procedure CodeEAN8(const ABarCode: string; vX: double; vY: double;
      BarHeight: double = 0; BarWidth: double = 0);
    procedure Code39(const ABarCode: string; vX: double; vY: double;
      BarHeight: double = 0; BarWidth: double = 0);

    property ProxyHost: string read fProxyHost write fProxyHost;
    property ProxyPort: string read fProxyPort write fProxyPort;
    property ProxyUser: string read fProxyUser write fProxyUser;
    property ProxyPass: string read fProxyPass write fProxyPass;
  end;

implementation

uses
  Math;

{ TFPDFScripts }

constructor TFPDFScripts.Create(AFPDF: TFPDFExt);
begin
  inherited Create;
  fpFPDF := AFPDF;
end;

{ TFPDFScriptCodeEAN }

procedure TFPDFScriptCodeEAN.CodeEAN13(const ABarCode: string; vX: double;
  vY: double; BarHeight: double; BarWidth: double);
var
  s, BinCode: string;
begin
  s := Trim(ABarCode);
  CheckBarCode(s, 13, 'EAN13');
  BinCode := CalcBinCode(s);
  DrawBarcode(BinCode, vx, vY, BarHeight, BarWidth);
end;

procedure TFPDFScriptCodeEAN.CodeEAN8(const ABarCode: string; vX: double;
  vY: double; BarHeight: double; BarWidth: double);
var
  s, BinCode: string;
begin
  s := Trim(ABarCode);
  CheckBarCode(s, 8, 'EAN8');
  BinCode := CalcBinCode(s);
  DrawBarcode(BinCode, vx, vY, BarHeight, BarWidth);
end;

procedure TFPDFScriptCodeEAN.CheckBarCode(var ABarCode: string;
  BarCodeLen: integer; const BarCodeName: string);
var
  l: integer;
begin
  ABarCode := Trim(ABarCode);
  l := Length(ABarCode);

  if (l < BarCodeLen - 1) then
    ABarCode := AdjustBarCodeSize(ABarCode, BarCodeLen - 1);

  if (l = BarCodeLen - 1) then
    ABarCode := ABarCode + IntToStr(GetCheckDigit(ABarCode, BarCodeName))
  else if (l = BarCodeLen) then
  begin
    if not TestCheckDigit(ABarCode, BarCodeName) then
      fpFPDF.Error(Format('Invalid %s Check Digit: %s', [BarCodeName, ABarCode]));
  end
  else
    fpFPDF.Error(Format('Invalid %s Code Len: %s', [BarCodeName, ABarCode]));
end;

function TFPDFScriptCodeEAN.AdjustBarCodeSize(const ABarCode: string;
  BarCodeLen: integer): string;
begin
  Result := Trim(copy(ABarCode, 1, BarCodeLen));
  if (BarCodeLen > Length(ABarCode)) then
    Result := StringOfChar('0', BarCodeLen - Length(Result)) + Result;
end;

function TFPDFScriptCodeEAN.GetCheckDigit(const ABarCode: string;
  const BarCodeName: string): integer;
var
  t, l, i: integer;
  v: integer;
begin
  //Compute the check digit
  t := 0;
  l := Length(ABarCode);
  for i := l downto 1 do
  begin
    v := StrToIntDef(ABarCode[i], -1);
    if (v < 0) then
      fpFPDF.Error(Format('Invalid Digits in %s: %s', [BarCodeName, ABarCode]));
    t := t + (v * IfThen(odd(i), 1, 3));
  end;

  Result := (10 - (t mod 10)) mod 10;
end;

function TFPDFScriptCodeEAN.TestCheckDigit(const ABarCode: string;
  const BarCodeName: string): boolean;
var
  l: integer;
begin
  l := Length(ABarCode);
  Result := (l > 0) and (StrToIntDef(ABarCode[l], -1) = GetCheckDigit(copy(ABarCode, 1, l-1), BarCodeName));
end;

function TFPDFScriptCodeEAN.CalcBinCode(const ABarCode: string): String;
type
 TParity = array[0..5] of Byte;
 
const
  codes: array[0..2] of array[0..9] of string =
    (('0001101', '0011001', '0010011', '0111101', '0100011', '0110001',
      '0101111', '0111011', '0110111', '0001011'),
     ('0100111', '0110011', '0011011', '0100001', '0011101', '0111001',
      '0000101', '0010001', '0001001', '0010111'),
     ('1110010', '1100110', '1101100', '1000010', '1011100', '1001110',
      '1010000', '1000100', '1001000', '1110100'));
  parities: array[0..9] of TParity =
    ((0, 0, 0, 0, 0, 0),
     (0, 0, 1, 0, 1, 1),
     (0, 0, 1, 1, 0, 1),
     (0, 0, 1, 1, 1, 0),
     (0, 1, 0, 0, 1, 1),
     (0, 1, 1, 0, 0, 1),
     (0, 1, 1, 1, 0, 0),
     (0, 1, 0, 1, 0, 1),
     (0, 1, 0, 1, 1, 0),
     (0, 1, 1, 0, 1, 0));
var
  BinCode: string;
  v, i, l, p, m: integer;
  pa: TParity;

begin
  l := Length(ABarCode);
  Result := '101';
  if odd(l) then
  begin
    p := 1;
    v := StrToInt(ABarCode[1]);
    pa := parities[v];
  end
  else
  begin
    p := 0;
    pa := parities[0];
  end;

  m := (l - p) div 2;
  for i := p+1 to m+p do
  begin
    v := StrToInt(ABarCode[i]);
    Result := Result + codes[pa[i-1-p], v];
  end;

  Result := Result + '01010';

  for i := m+1+p to l do
  begin
    v := StrToInt(ABarCode[i]);
    Result := Result + codes[2, v];
  end;

  Result := Result + '101';
end;

procedure TFPDFScriptCodeEAN.DrawBarcode(const BinCode: string; vX: double;
  vY: double; BarHeight: double; BarWidth: double);
var
  l, i: Integer;
begin
  if (BarHeight = 0) then
    BarHeight := cDefBarHeight;

  if (BarWidth = 0) then
    BarWidth := cDefBarWidth;

  //Draw bars
  l := Length(BinCode);
  for i := 1 to l do
    if (BinCode[i] = '1') then
      fpFPDF.Rect(vX+i*BarWidth, vY, BarWidth, BarHeight, 'F');
end;

{ TFPDFScriptCode39 }

procedure TFPDFScriptCode39.Code39(const ABarCode: string; vX: double;
  vY: double; BarHeight: double; BarWidth: double);
type
  TBarSeq = array[0..8] of Byte;
const
  Chars: String = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-. *$/+%';
  Bars: array[0..43] of TBarSeq =
    ( (0,0,0,1,1,0,1,0,0), (1,0,0,1,0,0,0,0,1), (0,0,1,1,0,0,0,0,1), (1,0,1,1,0,0,0,0,0),
      (0,0,0,1,1,0,0,0,1), (1,0,0,1,1,0,0,0,0), (0,0,1,1,1,0,0,0,0), (0,0,0,1,0,0,1,0,1),
      (1,0,0,1,0,0,1,0,0), (0,0,1,1,0,0,1,0,0), (1,0,0,0,0,1,0,0,1), (0,0,1,0,0,1,0,0,1),
      (1,0,1,0,0,1,0,0,0), (0,0,0,0,1,1,0,0,1), (1,0,0,0,1,1,0,0,0), (0,0,1,0,1,1,0,0,0),
      (0,0,0,0,0,1,1,0,1), (1,0,0,0,0,1,1,0,0), (0,0,1,0,0,1,1,0,0), (0,0,0,0,1,1,1,0,0),
      (1,0,0,0,0,0,0,1,1), (0,0,1,0,0,0,0,1,1), (1,0,1,0,0,0,0,1,0), (0,0,0,0,1,0,0,1,1),
      (1,0,0,0,1,0,0,1,0), (0,0,1,0,1,0,0,1,0), (0,0,0,0,0,0,1,1,1), (1,0,0,0,0,0,1,1,0),
      (0,0,1,0,0,0,1,1,0), (0,0,0,0,1,0,1,1,0), (1,1,0,0,0,0,0,0,1), (0,1,1,0,0,0,0,0,1),
      (1,1,1,0,0,0,0,0,0), (0,1,0,0,1,0,0,0,1), (1,1,0,0,1,0,0,0,0), (0,1,1,0,1,0,0,0,0),
      (0,1,0,0,0,0,1,0,1), (1,1,0,0,0,0,1,0,0), (0,1,1,0,0,0,1,0,0), (0,1,0,0,1,0,1,0,0),
      (0,1,0,1,0,1,0,0,0), (0,1,0,1,0,0,0,1,0), (0,1,0,0,0,1,0,1,0), (0,0,0,1,0,1,0,1,0) );
var
  wide, narrow, gap, lineWidth: Double;
  s: String;
  l, i, j, p: Integer;
  c: Char;
  seq: TBarSeq;
begin
  if (BarHeight = 0) then
    BarHeight := cDefBarHeight;

  if (BarWidth = 0) then
    BarWidth := cDefBarWidth;

  s := UpperCase(ABarCode);
  l := Length(s);
  if (l = 0) then
    Exit;

  wide := BarWidth;
  narrow := wide / 3 ;
  gap := narrow;

  if (s[l] <> '*') then
    s := s+'*';
  if (s[1] <> '*') then
    s := '*'+s;

  l := Length(s);
  for i := 1 to l do
  begin
    c := s[i];
    p := pos(c, Chars);
    if (p = 0) then
      fpFPDF.Error('Code39, invalid Char: '+c);

    seq := Bars[p-1];
    for j := 0 to High(seq) do
    begin
      lineWidth := IfThen(seq[j] = 0, narrow, wide);
      if ((j mod 2) = 0) then
        fpFPDF.Rect(vX, vY, lineWidth, BarHeight, 'F');

      vX := vX + lineWidth;
    end;

    vX := vX + gap;
  end;
end;

{ TFPDFScriptCode128 }

constructor TFPDFScriptCode128.Create(AFPDF: TFPDFExt);
begin
  inherited Create(AFPDF);

end;

procedure TFPDFScriptCode128.Code128(const ABarCode: string; vX: double;
  vY: double; BarHeight: double; BarWidth: double);
const
  C128Start: array[TCode128] of Byte = (103,104,105);  // Set selection characters at the start of C128
  C128Swap: array[TCode128] of Byte = (101,100,99);    // Set change characters

begin

end;


{ TFPDFExt }

procedure TFPDFExt.InternalCreate;
begin
  fProxyHost := '';
  fProxyPass := '';
  fProxyPort := '';
  fProxyUser := '';
end;

procedure TFPDFExt.Image(const vFileOrURL: string; vX: double; vY: double;
  vWidth: double; vHeight: double; const vLink: string);
var
  s, ext: string;
  ms: TMemoryStream;
  img: TFPDFImageInfo;
  i: integer;
begin
  //Put an image From Web on the page
  s := LowerCase(vFileOrURL);
  if ((Pos('http://', s) > 0) or (Pos('https://', s) > 0)) then
  begin
    img := FindUsedImage(vFileOrURL);
    if (img.Data = '') then
    begin
      ext := '';
      if (Pos('.jpg', s) > 0) or (Pos('.jpeg', s) > 0) then
        ext := 'JPG'
      else if (Pos('.png', s) > 0) then
        ext := 'PNG'
      else
        Error('Supported image not found in URL: ' + vFileOrURL);

      ms := TMemoryStream.Create;
      try
        GetImageFromURL(vFileOrURL, ms);
        inherited Image(ms, ext, vX, vY, vWidth, vHeight, vLink);
        i := Length(Self.images) - 1;
        Self.images[i].ImageName := vFileOrURL;
      finally
        ms.Free;
      end;
    end
    else
      inherited Image(img, vX, vY, vWidth, vHeight, vLink);
  end
  else
    inherited Image(vFileOrURL, vX, vY, vWidth, vHeight, vLink);
end;

procedure TFPDFExt.CodeEAN13(const ABarCode: string; vX: double; vY: double;
  BarHeight: double; BarWidth: double);
var
  script: TFPDFScriptCodeEAN;
begin
  script := TFPDFScriptCodeEAN.Create(Self);
  try
    script.CodeEAN13(ABarCode, vX, vY, BarHeight, BarWidth);
  finally
    script.Free;
  end;
end;

procedure TFPDFExt.CodeEAN8(const ABarCode: string; vX: double; vY: double;
  BarHeight: double; BarWidth: double);
var
  script: TFPDFScriptCodeEAN;
begin
  script := TFPDFScriptCodeEAN.Create(Self);
  try
    script.CodeEAN8(ABarCode, vX, vY, BarHeight, BarWidth);
  finally
    script.Free;
  end;
end;

procedure TFPDFExt.Code39(const ABarCode: string; vX: double; vY: double;
  BarHeight: double; BarWidth: double);
var
  script: TFPDFScriptCode39;
begin
  script := TFPDFScriptCode39.Create(Self);
  try
    script.Code39(ABarCode, vX, vY, BarHeight, BarWidth);
  finally
    script.Free;
  end;
end;

{$IfDef USESYNAPSE}
procedure TFPDFExt.GetImageFromURL(const aURL: string; const aResponse: TStream);
var
  vHTTP: THTTPSend;
  Ok: boolean;
begin
  vHTTP := THTTPSend.Create;
  try
    if (ProxyHost <> '') then
    begin
      vHTTP.ProxyHost := ProxyHost;
      vHTTP.ProxyPort := ProxyPort;
      vHTTP.ProxyUser := ProxyUser;
      vHTTP.ProxyPass := ProxyPass;
    end;
    Ok := vHTTP.HTTPMethod('GET', aURL);
    if Ok then
    begin
      aResponse.Seek(0, soBeginning);
      aResponse.CopyFrom(vHTTP.Document, 0);
    end
    else
      Error('Http Error: ' + IntToStr(vHTTP.ResultCode) +
        ' when downloading from: ' + aURL);
  finally
    vHTTP.Free;
  end;
end;

{$Else}
procedure TFPDFExt.GetImageFromURL(const aURL: string; const aResponse: TStream
  );
var
  vHTTP: TFPHTTPClient;
begin
  vHTTP := TFPHTTPClient.Create(nil);
  try
    if (ProxyHost <> '') then
    begin
      vHTTP.Proxy.Host := ProxyHost;
      vHTTP.Proxy.Port := StrToIntDef(ProxyPort, 0);
      vHTTP.Proxy.UserName := ProxyUser;
      vHTTP.Proxy.Password := ProxyPass;
    end;

    vHTTP.Get(aURL, aResponse);
  finally
    vHTTP.Free;
  end;
end;

{$EndIf}

end.

