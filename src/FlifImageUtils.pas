(*
    Delphi FLIF
    Copyright (C) 2017  Dzmitry Zhylko, LGPL v3+
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
	
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
	
    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*)

unit FlifImageUtils;

interface

uses
  Classes, SysUtils, Windows, Math;

type
  ///
  /// Pixel information storage structures
  ///

  /// RGB 8 bits
  PRGB = ^TRGB;
  TRGB = record
    R: Byte;
    G: Byte;
    B: Byte;
  end;
  PRGBList = ^TRGBList;
  TRGBList = array[0..0] of TRGB;

  /// BGR 8 bits
  PBGR = ^TBGR;
  TBGR = record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
  PBGRList = ^TBGRList;
  TBGRList = array[0..0] of TBGR;

  /// RGBA 8 bits
  PRGBA = ^TRGBA;
  TRGBA = record
    R: Byte;
    G: Byte;
    B: Byte;
    A: Byte;
  end;
  PRGBAList = ^TRGBAList;
  TRGBAList = array[0..0] of TRGBA;

  /// BGRA 8 bits
  PBGRA = ^TBGRA;
  TBGRA = record
    B: Byte;
    G: Byte;
    R: Byte;
    A: Byte;
  end;
  PBGRAList = ^TBGRAList;
  TBGRAList = array[0..1] of TBGRA;

  /// BGRA 16 bits
  PBGRA16 = ^TBGRA16;
  TBGRA16 = record
    B: Word;
    G: Word;
    R: Word;
    A: Word;
  end;
  PBGRAList16 = ^TBGRAList16;
  TBGRAList16 = array[0..1] of TBGRA16;

  /// RGBA 16 bits
  PRGBA16 = ^TRGBA16;
  TRGBA16 = record
    R: Word;
    G: Word;
    B: Word;
    A: Word;
  end;
  PRGBAList16 = ^TRGBAList16;
  TRGBAList16 = array[0..0] of TRGBA16;

  /// RGB 16 bits
  PRGB16 = ^TRGB16;
  TRGB16 = record
    R: Word;
    G: Word;
    B: Word;
  end;
  PRGBList16 = ^TRGBList16;
  TRGBList16 = array[0..0] of TRGB16;


  PDataStructur = ^TDataStructur;
  TDataStructur = record
    SourceData: PBGRAList;
    DestData: PRGBAList;
    StartPixel: NativeUInt;
    FinishPixel: NativeUInt;
  end;

  PDataStructur16 = ^TDataStructur16;
  TDataStructur16 = record
    SourceData: PBGRAList16;
    DestData: PRGBAList16;
    StartPixel: NativeUInt;
    FinishPixel: NativeUInt;
  end;

  PDataStructurBGRA2RGB = ^TDataStructurBGRA2RGB;
  TDataStructurBGRA2RGB = record
    SourceData: PBGRAList;
    DestData: PRGBList;
    StartPixel: NativeUInt;
    FinishPixel: NativeUInt;
  end;

  PBlendInfo = ^TBlendInfo;
  TBlendInfo = record
    Background: PByte;
    Forgeground: PByte;
    StartPixel: NativeUInt;
    FinishPixel: NativeUInt;
    UseSSE: Boolean;
  end;

procedure AlphaBlendBGRA(BackgroundBytes, ForgegroundBytes: PByte;
  PixelCount: NativeUInt; AUseSSE: Boolean);

procedure RGBA2BGRA(Source, Dest: Pointer; PixelCount: Integer); inline;
procedure BGRA2RGBA(Source, Dest: Pointer; PixelCount: Integer); inline;

procedure RGBA2BGRA16(Source, Dest: Pointer; PixelCount: NativeUInt); inline;
procedure BGRA2RGBA16(Source, Dest: Pointer; PixelCount: NativeUInt); inline;

procedure BGRA2RGB(Source, Dest: Pointer; PixelCount: NativeUInt); inline;

procedure BGR2RGB(Source, Dest: PByte; DataSize: NativeUInt);

/// <summary>
///   RGBRGB => BGRABGRA
/// </summary>
procedure BGR2RGBA(Source, Dest: PByte; SourceSize: NativeUInt);
procedure BGR2RGBAa(Source, Dest: PByte; Width, Height: Integer; RowSize: NativeUInt);
procedure BGR2RGBa_(Source, Dest: PByte; Width, Height: Integer;
  RowSize: NativeUInt);
procedure RGBA16toBGRA8(Source, Dest: PByte; PixelCount: NativeUInt);
procedure RGBA16toRGBA8(Source, Dest: PByte; PixelCount: NativeUInt);

procedure RGBA2A(SourceData, DestData: PByte; PixelCount: NativeUInt);
procedure RGBAandA(RGBAData, AData: PByte; PixelCount: NativeUInt);
procedure RGB2RGBA(Source, Dest, Alpha: Pointer; PixelCount: Integer);
procedure RGB2RGBA16_A8(SourceHi, SourceLo, Dest, Alpha: Pointer; PixelCount: Integer);
procedure BGRA2BGRandA(Source, Dest, Alpha: Pointer; PixelCount: NativeUInt);
procedure RGBAsetAlpha(Source: Pointer; Alpha: Byte; PixelCount: Integer);
function IsGrayScalePalette(Source: Pointer; ColorsCount: Integer): Boolean; inline;


procedure TimerReset(var Data: Int64); inline;
function TimerGetOffset(const Data: Int64): Double; inline;

var
  __Freq: Int64;
  PaletteGray: TMaxLogPalette;

implementation

var
  __SSE_EXIST: Boolean = False;

procedure RGBA2BGRA(Source, Dest: Pointer; PixelCount: Integer);
begin
  BGRA2RGBA(Source, Dest, PixelCount);
end;

procedure BGRA2RGBA(Source, Dest: Pointer; PixelCount: Integer);
var
  i: Integer;
  Tmp: TBGRA;
  S: PBGRAList;
  D: PRGBAList;
begin
  S := PBGRAList(Source);
  D := PRGBAList(Dest);
  i := 0;
  repeat
    Tmp := S[i];
    D[i].R := Tmp.R;
    D[i].G := Tmp.G;
    D[i].B := Tmp.B;
    D[i].A := Tmp.A;

    Inc(i);
    Dec(PixelCount);
  until PixelCount = 0;
end;

procedure RGBA2BGRA16(Source, Dest: Pointer; PixelCount: NativeUInt); inline;
begin
  BGRA2RGBA16(Source, Dest, PixelCount);
end;

procedure BGRA2RGBA16(Source, Dest: Pointer; PixelCount: NativeUInt);
var
  S: PBGRAList16;
  D: PRGBAList16;
  Tmp: TBGRA16;
  i: Integer;
begin
  S := PBGRAList16(Source);
  D := PRGBAList16(Dest);
  i := 0;
  repeat
    Tmp := S[i];
    D[i].R := Tmp.R;
    D[i].G := Tmp.G;
    D[i].B := Tmp.B;
    D[i].A := Tmp.A;

    Inc(i);
    Dec(PixelCount);
  until PixelCount = 0;
end;

procedure BGRA2RGB(Source, Dest: Pointer; PixelCount: NativeUInt);
var
  i: NativeUInt;
  S: PBGRAList;
  D: PRGBList;
begin
  S := PBGRAList(Source);
  D := PRGBList(Dest);

  i := 0;
  if PixelCount > 0 then
    repeat
      D[i].R := S[i].R;
      D[i].G := S[i].G;
      D[i].B := S[i].B;

      Inc(i);
      Dec(PixelCount);
    until PixelCount = 0;
end;

procedure BGR2RGB(Source, Dest: PByte; DataSize: NativeUInt);
var
  S: PBGRList;
  D: PRGBList;
  i, c: NativeUInt;
  Tmp: TBGR;
begin
  S := PBGRList(Source);
  D := PRGBList(Dest);
  c := DataSize div 3;
  for i := 0 to c - 1 do
  begin
    Tmp := S[i];
    D[i].R := Tmp.R;
    D[i].G := Tmp.G;
    D[i].B := Tmp.B;
  end;
end;

{$IFDEF Win32}
/// <summary>
///FastDIB: sourceforge.net/projects/tfastdib
/// </summary>
procedure xLine_DrawAlpha32_SSE(Src, Dst : Pointer; Count : Integer);
Const
  Mask : Int64 = $000000FF00FF00FF;
asm
  push esi
  mov esi, eax
  lea eax, [Mask]
  db $0F,$6F,$28           /// movq mm5, [eax]  // mm5 - $0000.00FF|00FF.00FF
  db $0F,$EF,$FF           /// pxor      mm7, mm7    // mm7 = 0
@inner_loop:

  mov       eax, [esi]
  test      eax, $FF000000
  jz        @noblend

  db $0F,$6E,$06           /// movd      mm0, [esi]
  db $0F,$6E,$0A           /// movd      mm1, [edx]
  db $0F,$60,$C7           /// punpcklbw mm0, mm7    // mm0 - src
  db $0F,$60,$CF           /// punpcklbw mm1, mm7    // mm1 - dst
  db $0F,$70,$F0,$FF       /// pshufw mm6, mm0, 255  // mm6 - src alpha
  //  db $0F,$DB,$F5           /// pand mm6, mm5
    // clear alpha component of mm6 - can be skipped if not needed

//  add       esi, 4

  db $0F,$D5,$C6           /// pmullw    mm0, mm6    // получить произведение источника в mm0
  db $0F,$EF,$F5           /// pxor      mm6, mm5    // получить обратную прозрачность в mm6
  db $0F,$D5,$CE           /// pmullw    mm1, mm6    // получить произведение источника в mm0

  db $0F,$FD,$C1           /// paddw     mm0, mm1    // сложить
  db $0F,$71,$D0,$08       /// psrlw     mm0, 8      // переместить в младшую сторону для упаковки
  db $0F,$67,$C7           /// packuswb  mm0, mm7    // упаковать перед записью на место
  db $0F,$7E,$02           /// movd      [edx], mm0  // записать результат
@noblend:
  add       esi, 4
  add       edx, 4
  dec       ecx
  jnz       @inner_loop
  db $0F,$77               /// emms
  pop esi
end;
{$ENDIF}

{$IFDEF CPUX64}
/// <summary>
/// FastDIB: sourceforge.net/projects/tfastdib
/// <para>
///   // Src = rcx, Dst = rdx, Count = r8, AlphaC = r9
/// </para>
/// </summary>
procedure xLine_DrawAlpha32_SSE(Src, Dst : Pointer; Count, AlphaC : Integer);
Const Mask : Int64 = $000000FF00FF00FF;
asm
  movq mm5, Mask  // mm5 - $0000.00FF|00FF.00FF
  pxor mm7, mm7    // mm7 = 0
  mov eax, AlphaC
  movd mm0, eax
  pshufw mm4, mm0, 0  // mm4 - const alpha
@inner_loop:
  mov       eax, [rcx]
  test      eax, $FF000000 // alpha = 0 - can skip blending; this check
  jz        @noblend       // makes proc faster at CoreDuo, but slower at P4 (also depends on data)

  movd      mm0, [rcx]
//  movd      mm0, eax
  movd      mm1, [rdx]
  punpcklbw mm0, mm7    // mm0 - src
  punpcklbw mm1, mm7    // mm1 - dst
  pshufw mm6, mm0, 255  // mm6 - src alpha
  pmullw mm6, mm4       // alpha = alpha * [const alpha]
  psrlw  mm6, 8

//  pand mm6, mm5
    // clear alpha component of mm6 - can be skipped if not needed

  pmullw    mm0, mm6    // src = src * alpha
  pxor      mm6, mm5    // alpha = 1 - alpha
  pmullw    mm1, mm6    // dst = dst * (1 - alpha)

  paddw     mm0, mm1    // src = src + dst
  psrlw     mm0, 8      // div 256
  packuswb  mm0, mm7    // packing to bytes
  movd      [rdx], mm0
@noblend:
  add       rcx, 4
  add       rdx, 4
  dec       r8
  jnz       @inner_loop
  emms
end;
{$ENDIF}

procedure AlphaBlendRGBABlendColor(Fg, Bg: PRGBA); inline;
var
  Alpha, InvAlpha: Cardinal;
begin
  Alpha := Fg^.A + 1;
  InvAlpha := 256 - Fg^.A;
  Bg^.R := Byte((Alpha * Fg^.R + InvAlpha * Bg^.R) shr 8);
  Bg^.G := Byte((Alpha * Fg^.G + InvAlpha * Bg^.G) shr 8);
  Bg^.B := Byte((Alpha * Fg^.B + InvAlpha * Bg^.B) shr 8);
end;

procedure AlphaBlendBGRA(BackgroundBytes, ForgegroundBytes: PByte;
  PixelCount: NativeUInt; AUseSSE: Boolean);
var
  S, D: PBGRAList;
  UseSSE: Boolean;
  i: NativeUInt;
begin
  UseSSE := AUseSSE{$IFDEF Win32} and __SSE_EXIST{$ELSE}{$IFDEF CPUX64} and __SSE_EXIST{$ELSE} and False{$ENDIF}{$ENDIF};
  if UseSSE then
  begin
    xLine_DrawAlpha32_SSE(ForgegroundBytes, BackgroundBytes, PixelCount{$IFDEF CPUX64}, 255{$ENDIF});
  end
  else
  begin
    S := PBGRAList(ForgegroundBytes);
    D := PBGRAList(BackgroundBytes);

    i := 0;
    if PixelCount > 0 then
      repeat
        AlphaBlendRGBABlendColor(@S[i], @D[i]);

        Inc(i);
        Dec(PixelCount);
      until (PixelCount = 0);
  end;
end;

procedure BGR2RGBA(Source, Dest: PByte; SourceSize: NativeUInt);
var
  SL: PBGRList;
  DL: PRGBAList;
  i, PixelNumbers: NativeUInt;
begin
  SL := PBGRList(Source);
  DL := PRGBAList(Dest);
  PixelNumbers := SourceSize div 3;
  for i := 0 to PixelNumbers - 1 do
  begin
    DL[i].R := SL[i].R;
    DL[i].G := SL[i].G;
    DL[i].B := SL[i].B;
    DL[i].A := 0;
  end;
end;

procedure BGR2RGBAa(Source, Dest: PByte; Width, Height: Integer;
  RowSize: NativeUInt);
var
  SL: PBGRList;
  DL: PRGBAList;
  x, y, i: Integer;
begin
  i := 0;
  DL := PRGBAList(Dest);
  for y := 0 to Height - 1 do
  begin
    SL := PBGRList(@Source[RowSize * NativeUInt(y)]);

    for x := 0 to Width - 1 do
    begin
      DL[i].R := SL[x].R;
      DL[i].G := SL[x].G;
      DL[i].B := SL[x].B;
      DL[i].A := 255;

      Inc(i);
    end;
  end;
end;

procedure BGR2RGBa_(Source, Dest: PByte; Width, Height: Integer;
  RowSize: NativeUInt);
var
  SL: PBGRList;
  DL: PRGBList;
  x, y, i: Integer;
begin
  i := 0;
  DL := PRGBList(Dest);
  for y := 0 to Height - 1 do
  begin
    SL := PBGRList(@Source[RowSize * NativeUInt(y)]);

    for x := 0 to Width - 1 do
    begin
      DL[i].R := SL[x].R;
      DL[i].G := SL[x].G;
      DL[i].B := SL[x].B;

      Inc(i);
    end;
  end;
end;

procedure RGBA2A(SourceData, DestData: PByte; PixelCount: NativeUInt);
var
  j: NativeUInt;
  Source: PRGBAList;
begin
  j := 0;
  Source := PRGBAList(SourceData);
  if PixelCount > 0 then
  begin
    repeat
      DestData[j] := Source^[j].A;
      Inc(j);
    until j >= PixelCount;
  end;
end;

procedure RGBAandA(RGBAData, AData: PByte; PixelCount: NativeUInt);
var
  i, j: NativeUInt;
  Source: PRGBAList;
begin
  i := PixelCount;
  j := 0;
  Source := PRGBAList(RGBAData);
  if i > 0 then
  begin
    repeat
      Source^[j].A := AData[j];
      Dec(i);
      Inc(j);
    until i = 0;
  end;
end;

procedure RGBA16toBGRA8(Source, Dest: PByte; PixelCount: NativeUInt);
var
  S: PRGBAList16;
  D: PBGRAList;
  i: NativeUInt;
  Tmp: TRGBA16;
begin
  S := PRGBAList16(Source);
  D := PBGRAList(Dest);
  i := 0;

  if PixelCount > 0 then
    repeat
      Tmp := S[i];
      D[i].R := Byte(Tmp.R div 256);
      D[i].G := Byte(Tmp.G div 256);
      D[i].B := Byte(Tmp.B div 256);
      D[i].A := Byte(Tmp.A div 256);

      Inc(i);
      Dec(PixelCount);
    until (PixelCount = 0);
end;

procedure RGBA16toRGBA8(Source, Dest: PByte; PixelCount: NativeUInt);
var
  S: PRGBAList16;
  D: PRGBAList;
  i: NativeUInt;
  Tmp: TRGBA16;
begin
  S := PRGBAList16(Source);
  D := PRGBAList(Dest);
  i := 0;

  if PixelCount > 0 then
    repeat
      Tmp := S[i];
      D[i].R := Byte(Tmp.R div 256);
      D[i].G := Byte(Tmp.G div 256);
      D[i].B := Byte(Tmp.B div 256);
      D[i].A := Byte(Tmp.A div 256);


      Inc(i);
      Dec(PixelCount);
    until (PixelCount = 0);
end;

procedure RGB2RGBA(Source, Dest, Alpha: Pointer; PixelCount: Integer);
var
  S: PRGBList;
  D: PRGBAList;
  i: Integer;
begin
  S := PRGBList(Source);
  D := PRGBAList(Dest);
  i := 0;
  if PixelCount > 0 then
    repeat
      D[i].R := S[i].R;
      D[i].G := S[i].G;
      D[i].B := S[i].B;
      D[i].A := PByte(Alpha)[i];

      Inc(i);
      Dec(PixelCount);
    until PixelCount = 0;
end;

procedure RGB2RGBA16_A8(SourceHi, SourceLo, Dest, Alpha: Pointer; PixelCount: Integer);
var
  SH, SL: PRGBList;
  D: PRGBAList16;
  i: Integer;
begin
  SH := PRGBList(SourceHi);
  SL := PRGBList(SourceLo);
  D := PRGBAList16(Dest);
  i := 0;
  if PixelCount > 0 then
    repeat
      D[i].R := MakeWord(SL[i].R, SH[i].R);
      D[i].G := MakeWord(SL[i].G, SH[i].G);
      D[i].B := MakeWord(SL[i].B, SH[i].B);

      D[i].A := PByte(Alpha)[i] * 256;

      Inc(i);
      Dec(PixelCount);
    until PixelCount = 0;
end;

procedure BGRA2BGRandA(Source, Dest, Alpha: Pointer; PixelCount: NativeUInt);
var
  i: Integer;
  S: PBGRAList;
  D: PBGRList;
begin
  S := PBGRAList(Source);
  D := PBGRList(Dest);
  i := 0;
  if PixelCount > 0 then
    repeat
      D[i].B := S[i].B;
      D[i].G := S[i].G;
      D[i].R := S[i].R;
      PByte(Alpha)[i] := S[i].A;

      Dec(PixelCount);
      Inc(i);
    until PixelCount = 0;
end;

procedure RGBAsetAlpha(Source: Pointer; Alpha: Byte; PixelCount: Integer);
var
  S: PRGBAList;
  i: Integer;
begin
  S := PRGBAList(Source);
  for i := 0 to PixelCount - 1 do
  begin
    S[i].A := Alpha;
  end;
end;

function IsGrayScalePalette(Source: Pointer; ColorsCount: Integer): Boolean;
var
  S: PBGRAList;
  i: Integer;
begin
  Result := ColorsCount = 256;
  if Result then
  begin
    S := PBGRAList(Source);
    for i := 0 to 255 do
    begin
      Result := (S[i].B = S[i].G) and (S[i].B = S[i].R) and (S[i].B = i);
      if not Result then
        Break;
    end;
  end;
end;

procedure TimerReset(var Data: Int64); inline;
begin
  QueryPerformanceCounter(Data);
end;

function TimerGetOffset(const Data: Int64): Double; inline;
var
  NC: Int64;
begin
  QueryPerformanceCounter(NC);
  Result := (NC - Data) / __Freq;
end;

procedure InitPaletteGray;
var
  i: Integer;
begin
  PaletteGray.palVersion := $300;
  PaletteGray.palNumEntries := 256;
  for i := 0 to 255 do
  begin
    PaletteGray.palPalEntry[i].peRed := i;
    PaletteGray.palPalEntry[i].peGreen := i;
    PaletteGray.palPalEntry[i].peBlue := i;
    PaletteGray.palPalEntry[i].peFlags := 0;
  end;
end;

initialization
  QueryPerformanceFrequency(__Freq);
  __SSE_EXIST := IsProcessorFeaturePresent(PF_XMMI_INSTRUCTIONS_AVAILABLE);
  InitPaletteGray;

end.
