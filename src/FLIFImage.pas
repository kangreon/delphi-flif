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

unit FLIFImage;

interface

{$I flif.inc}

uses
  Windows, Graphics, Classes, SysUtils, flif, FlifImageUtils,
  {$ifdef flif_include_png}
  PngImage,
  {$endif}
  {$ifdef flif_include_jpeg}
  jpeg,
  {$endif}
  Math;

type
  TFlifImageType = (fitRGB, fitRGBA, fitHDR, fitGRAY, fitPALETTE);
  TFlifCodeQuality = 0..100;

  TDecoderSettings = class
  private
    FQuality: TFlifCodeQuality;
    FCrcCheck: Boolean;
    FFitChange: Boolean;
    FResizeChange: Boolean;
    FScale: NativeUInt;
    FResize: TSize;
    FFit: TSize;
    procedure SetScale(const Value: NativeUInt);
    procedure SetFit(const Value: TSize);
    procedure SetResize(const Value: TSize);
  public
    constructor Create;

    procedure Apply(Decoder: TFLIFDecoder);
    procedure Default;

    property CrcCheck: Boolean read FCrcCheck write FCrcCheck;
    property Fit: TSize read FFit write SetFit;
    property Quality: TFlifCodeQuality read FQuality write FQuality;
    property Resize: TSize read FResize write SetResize;
    property Scale: NativeUInt read FScale write SetScale;
  end;

  TEncoderSettings = class
  private
    FInterlaced: Boolean;
    FInterlacedChange: Boolean;
    FLearnRepeat: UInt32;
    FLearnRepeatChange: Boolean;
    FAutoColorBuckets: Boolean;
    FAutoColorBucketsChange: Boolean;
    FPaletteSize: UInt32;
    FPaletteSizeChange: Boolean;
    FLookback: Boolean;
    FLookbackChange: Boolean;
    FDivisor: Int32;
    FDivisorChange: Boolean;
    FMinSize: Int32;
    FMinSizeChange: Boolean;
    FSplitThreshold: Int32;
    FSplitThresholdChange: Boolean;
    FAlphaZeroLossless: Boolean;
    FAlphaZeroLosslessChange: Boolean;
    FChanceCutoff: Int32;
    FChanceCutoffChange: Boolean;
    FChanceAlpha: Int32;
    FChanceAlphaChange: Boolean;
    FCrcCheck: Boolean;
    FCrcCheckChange: Boolean;
    FChannelCompact: Boolean;
    FChannelCompactChange: Boolean;
    FYcocg: Boolean;
    FYcocgChange: Boolean;
    FFrameShape: Boolean;
    FFrameShapeChange: Boolean;
    FLossy: TFlifCodeQuality;
    FLossyChange: Boolean;
    FChange: Boolean;
    procedure SetPaletteSize(const Value: UInt32);
    procedure GetAlphaZeroLossless(const Value: Boolean);
    procedure SetAutoColorBuckets(const Value: Boolean);
    procedure SetChanceAlpha(const Value: Int32);
    procedure SetChanceCutoff(const Value: Int32);
    procedure SetChannelCompact(const Value: Boolean);
    procedure SetCrcCheck(const Value: Boolean);
    procedure SetDivisor(const Value: Int32);
    procedure SetFrameShape(const Value: Boolean);
    procedure SetInterlaced(const Value: Boolean);
    procedure SetLearnRepeat(const Value: UInt32);
    procedure SetLookback(const Value: Boolean);
    procedure SetLossy(const Value: TFlifCodeQuality);
    procedure SetMinSize(const Value: Int32);
    procedure SetSplitThreshold(const Value: Int32);
    procedure SetYcocg(const Value: Boolean);
  public
    constructor Create;

    procedure Apply(Encoder: TFLIFEncoder);
    procedure Default;

    property IsChange: Boolean read FChange;

    property AutoColorBuckets: Boolean read FAutoColorBuckets write SetAutoColorBuckets;
    property AlphaZeroLossless: Boolean read FAlphaZeroLossless write GetAlphaZeroLossless;
    property ChanceAlpha: Int32 read FChanceAlpha write SetChanceAlpha;
    property ChanceCutoff: Int32 read FChanceCutoff write SetChanceCutoff;
    property ChannelCompact: Boolean read FChannelCompact write SetChannelCompact;
    property CrcCheck: Boolean read FCrcCheck write SetCrcCheck;
    property Divisor: Int32 read FDivisor write SetDivisor;
    property FrameShape: Boolean read FFrameShape write SetFrameShape;
    property Interlaced: Boolean read FInterlaced write SetInterlaced;
    property LearnRepeat: UInt32 read FLearnRepeat write SetLearnRepeat;
    property Lookback: Boolean read FLookback write SetLookback;
    property Lossy: TFlifCodeQuality read FLossy write SetLossy;
    property MinSize: Int32 read FMinSize write SetMinSize;
    property PaletteSize: UInt32 read FPaletteSize write SetPaletteSize;
    property SplitThreshold: Int32 read FSplitThreshold write SetSplitThreshold;
    property Ycocg: Boolean read FYcocg write SetYcocg;
  end;

  TPaletteList = array[Byte] of TBGRA;

  TBitmapInfoEx = record
    bmiHeader: TBitmapInfoHeader;
    bmiColors: array[Byte] of TRGBQuad;
  end;

  TFLIFImage = class(TGraphic)
  private
    FBitmap: HBITMAP;
    FBitmapDC: HDC;

    FCanvas: TCanvas;
    FChannels: Byte;
    FDepth: Byte;
    FData: PByte;
    FDataSize: NativeUInt;
    /// <summary>
    ///   BBGGRRAABBGGRRAA...
    /// </summary>
    FExtraData: PByte;
    FExtraDataSize: NativeUInt;
    FRowSize: NativeUInt;
    FPixelRowSize: NativeUInt;
    FExtraRowSize: NativeUInt;
    FInfo: TBitmapInfoEx;
    FPaletteExist: Boolean;
    FPalette: TPaletteList;
    FPaletteCount: NativeUInt;
    FImageType: TFlifImageType;
    FDecoder: TDecoderSettings;
    FEncoder: TEncoderSettings;
    FStretchType: Cardinal;
    FTemp: TMemoryStream;
    FTempExist: Boolean;

    procedure LoadPixelsFromFlifImage(Image: TFLIFImagePointer);
    procedure DrawImage(DC: HDC; Rect: TRect);
    procedure Clear;
    /// <summary>
    ///   Load from TPngImage (RGB, GRAY, PALETTE, RGBA, RGBA16)
    /// </summary>
    {$ifdef flif_include_png}
    procedure AssignFromPng(Image: TPngImage);
    procedure AssignToPng(Image: TPngImage);
    function GetPng: TPngImage;
    function GetPNGColor: Cardinal;
    procedure WriteDataFromPNG(Image: TPngImage);
    {$endif}
    {$ifdef flif_include_jpeg}
    procedure AssignFromJpeg(Image: TJPEGImage);
    procedure AssignToJpeg(Image: TJPEGImage);
    {$endif}
    {$ifdef flif_include_bitmap}
    procedure AssignFromBitmap(Bitmap: TBitmap);
    procedure AssignToBitmap(Bitmap: TBitmap);
    function GetBitmap(Bitmap: TBitmap): TBitmap;{$endif}


    procedure SetImageTypeAndInitStruct(AChannels, ADepth: Byte;
      const APaletteSize, AWidth, AHeight: NativeUInt);
    function GetScanLine(Y: Integer): PByte;
    procedure CreateCanvas;
    procedure CanvasChange(Sender: TObject);
    procedure StretchImageAlpha(DC: HDC; Rect: TRect);

    function SavePixelsToFlif: TFLIFImagePointer;
    procedure SetStretchType(const Value: Cardinal);
  protected
    function GetEmpty: Boolean; override;
    function GetHeight: Integer; override;
    function GetWidth: Integer; override;
    function GetTransparent: Boolean; override;

    procedure SetHeight(Value: Integer); override;
    procedure SetWidth(Value: Integer); override;
    procedure AssignTo(Dest: TPersistent); override;
  public
    constructor Create; override;
    destructor Destroy; override;

    procedure Assign(Source: TPersistent); override;

    procedure LoadFromStream(Stream: TStream); override;
    procedure SaveToStream(Stream: TStream); override;

    procedure LoadFromClipboardFormat(AFormat: Word; AData: NativeUInt;
      APalette: HPALETTE); override;
    procedure SaveToClipboardFormat(var AFormat: Word; var AData: NativeUInt;
      var APalette: HPALETTE); override;

    procedure Draw(ACanvas: TCanvas; const Rect: TRect); override;

    property Decoder: TDecoderSettings read FDecoder;
    property Encoder: TEncoderSettings read FEncoder;

    property ImageType: TFlifImageType read FImageType;
    property PaletteExist: Boolean read FPaletteExist;
    property Palette: TPaletteList read FPalette;

    /// <summary>
    ///   Return one line with pixels: bgra8888, bgr888, gray8, palette8
    /// </summary>
    property ScanLine[Y: Integer]: PByte read GetScanLine;

    property StretchType: Cardinal read FStretchType write SetStretchType;

    property Channels: Byte read FChannels;
    property Depth: Byte read FDepth;
  end;

implementation

{ TFLIFImage }

constructor TFLIFImage.Create;
begin
  FCanvas := TCanvas.Create;
  FDecoder := TDecoderSettings.Create;
  FEncoder := TEncoderSettings.Create;
  FStretchType := HALFTONE;
  FTemp := TMemoryStream.Create;
  FTempExist := False;
  FBitmap := 0;
  FBitmapDC := 0;

  Clear;
  inherited;
end;

destructor TFLIFImage.Destroy;
begin
  Clear;
  FTemp.Free;
  FEncoder.Free;
  FDecoder.Free;
  FCanvas.Free;
  inherited;
end;

procedure TFLIFImage.Clear;
begin
  if (FDataSize > 0) and Assigned(FData) then
    FreeMemory(FData);

  if (FExtraDataSize > 0) and Assigned(FExtraData) then
    FreeMemory(FExtraData);

  if FBitmap <> 0 then
  begin
    DeleteObject(FBitmap);
    FBitmap := 0;
  end;

  if FBitmapDC <> 0 then
  begin
    DeleteDC(FBitmapDC);
    FBitmapDC := 0;
  end;

  FData := nil;
  FExtraData := nil;
  FChannels := 0;
  FDepth := 0;
  FDataSize := 0;
  FExtraDataSize := 0;
  FRowSize := 0;
  FPixelRowSize := 0;
  FExtraRowSize := 0;
  FPaletteExist := False;
  FPaletteCount := 0;
  FImageType := fitRGBA;
  FTempExist := False;
  FTemp.Size := 0;
end;

procedure TFLIFImage.Assign(Source: TPersistent);
begin
  Clear;

  {$ifdef flif_include_png}
  if Source is TPngImage then
  begin
    AssignFromPng(TPngImage(Source));
  end
  else {$endif}
  {$ifdef flif_include_jpeg}
  if Source is TJPEGImage then
  begin
    AssignFromJpeg(TJPEGImage(Source));
  end
  else
  {$endif}
  {$ifdef flif_include_bitmap}
  if Source is TBitmap then
  begin
    AssignFromBitmap(TBitmap(Source));
  end
  else
  {$endif}
    inherited;
end;

procedure TFLIFImage.AssignTo(Dest: TPersistent);
begin
  if Dest is TFLIFImage then
  begin
    TFLIFImage(Dest).Clear;
    TFLIFImage(Dest).FChannels := FChannels;
    TFLIFImage(Dest).FDepth := FDepth;
    TFLIFImage(Dest).FDataSize := FDataSize;
    TFLIFImage(Dest).FExtraDataSize := FExtraDataSize;
    TFLIFImage(Dest).FRowSize := FRowSize;
    TFLIFImage(Dest).FPixelRowSize := FPixelRowSize;
    TFLIFImage(Dest).FExtraRowSize := FExtraRowSize;
    TFLIFImage(Dest).FInfo := FInfo;
    TFLIFImage(Dest).FPaletteExist := FPaletteExist;
    TFLIFImage(Dest).FPaletteCount := FPaletteCount;
    TFLIFImage(Dest).FImageType := FImageType;

    if FDataSize > 0 then
    begin
      TFLIFImage(Dest).FData := GetMemory(FDataSize);
      Move(FData^, TFLIFImage(Dest).FData^, FDataSize);
    end;

    if FExtraDataSize > 0 then
    begin
      TFLIFImage(Dest).FExtraData := GetMemory(FExtraDataSize);
      Move(FExtraData^, TFLIFImage(Dest).FExtraData^, FExtraDataSize);
    end;

    if FPaletteExist and (FPaletteCount > 0) then
    begin
      Move(FPalette[0].B, TFLIFImage(Dest).FPalette[0].B, FPaletteCount * 4);
    end;

    TFLIFImage(Dest).CreateCanvas;
  end
  {$ifdef flif_include_png}
  else if Dest is TPngImage then
  begin
    AssignToPng(TPngImage(Dest));
  end
  {$endif}
  {$ifdef flif_include_bitmap}
  else if Dest is TBitmap then
  begin
    AssignToBitmap(TBitmap(Dest));
  end
  {$endif}
  {$ifdef flif_include_jpeg}
  else if Dest is TJPEGImage then
  begin
    AssignToJpeg(TJPEGImage(Dest));
  end
  {$endif}
  else
    inherited;
end;

procedure TFLIFImage.CreateCanvas;
var
  BufferBits: Pointer;
  Info: TBitmapInfoEx;
begin
  Info := FInfo;

  if FPaletteExist then
  begin
    Move(FPalette[0].B, Info.bmiColors[0].rgbBlue, FPaletteCount * 4);

    Info.bmiHeader.biClrUsed := FPaletteCount;
    Info.bmiHeader.biClrImportant := FPaletteCount;
  end
  else if FImageType = fitGRAY then
  begin
    // Copy grayscale palette
    Move(PaletteGray.palPalEntry[0].peRed, Info.bmiColors[0].rgbBlue, 256 * 4);

    Info.bmiHeader.biClrUsed := 256;
    Info.bmiHeader.biClrImportant := 256;
  end;

  FBitmapDC := CreateCompatibleDC(0);
  FBitmap := CreateDIBSection(FBitmapDC, TBitmapInfo(Pointer(@Info)^),
    DIB_RGB_COLORS, BufferBits, 0, 0);
  Move(FData^, BufferBits^, FDataSize);
  SelectObject(FBitmapDC, FBitmap);

  FCanvas.Handle := FBitmapDC;
  FCanvas.OnChange := CanvasChange;
end;

procedure TFLIFImage.CanvasChange(Sender: TObject);
begin
  //todo: palette? rgba16?
  GetDIBits(FCanvas.Handle, FBitmap, 0, Height, FData,
    TBitmapInfo(Pointer(@FInfo)^), BI_RGB);
end;

procedure TFLIFImage.StretchImageAlpha(DC: HDC; Rect: TRect);
var
  BitmapDestRGBA, BitmapSource, BitmapDest: TBitmap;
  BufferDC: HDC;
  BufferBitmap, OldBitmap: HBITMAP;
  W, H, y: Integer;
  BufferBits: Pointer;
  DataAlpha: PByte;
  BitmapInfo: TBitmapInfo;
begin
  W := Rect.Width;
  H := Rect.Height;

  BitmapDestRGBA := TBitmap.Create;
  try

    DataAlpha := GetMemory(Width * Height);
    BitmapSource := TBitmap.Create;
    BitmapDest := TBitmap.Create;
    try
      RGBA2A(FData, DataAlpha, Width * Height);

      BitmapSource.PixelFormat := pf8bit;
      BitmapDest.PixelFormat := pf8bit;
      BitmapDestRGBA.PixelFormat := pf32bit;
      BitmapSource.SetSize(Width, Height);
      BitmapDest.SetSize(W, H);
      BitmapDestRGBA.SetSize(W, H);

      for y := 0 to Height - 1 do
      begin
        Move(DataAlpha[y * Width], BitmapSource.ScanLine[y]^, Width);
      end;

      SetStretchBltMode(BitmapDest.Canvas.Handle, FStretchType);
      SetStretchBltMode(BitmapSource.Canvas.Handle, FStretchType);
      SetStretchBltMode(BitmapDestRGBA.Canvas.Handle, FStretchType);

      BitmapDest.Canvas.StretchDraw(BitmapDest.Canvas.ClipRect, BitmapSource);
      StretchBlt(BitmapDestRGBA.Canvas.Handle, 0, 0, W, H, FCanvas.Handle,
        0, 0, Width, Height, SRCCOPY);

      for y := 0 to H - 1 do
        RGBAandA(BitmapDestRGBA.ScanLine[y], BitmapDest.ScanLine[y], W);
    finally
      BitmapSource.Free;
      BitmapDest.Free;

      FreeMemory(DataAlpha);
    end;

    with BitmapInfo.bmiHeader do
    begin
      biSize := sizeof(TBitmapInfoHeader);
      biPlanes := 1;
      biBitCount := 32;
      biCompression := BI_RGB;
      biWidth := W;
      biHeight := -Integer(H);
    end;

    BufferDC := CreateCompatibleDC(0);
    BufferBitmap := CreateDIBSection(BufferDC, BitmapInfo, DIB_RGB_COLORS, BufferBits, 0, 0);
    try
      if (BufferBitmap = 0) or (BufferBits = nil) then
        RaiseLastOSError;

      OldBitmap := SelectObject(BufferDC, BufferBitmap);
      try
        // Draw background image
        BitBlt(BufferDC, 0, 0, W, H, DC, Rect.Left, Rect.Top, SRCCOPY);

        // Draw foreground image with alpha channel
        for y := 0 to h - 1 do
          AlphaBlendBGRA(@PByte(BufferBits)[W * y * 4], BitmapDestRGBA.ScanLine[y], W, False);

        BitBlt(DC, Rect.Left, Rect.Top, W, H, BufferDC, 0, 0, SRCCOPY);
      finally
        SelectObject(BufferDC, OldBitmap);
      end;
    finally
      if BufferBitmap <> 0 then
        DeleteObject(BufferBitmap);

      if BufferDC <> 0 then
        DeleteDC(BufferDC);
    end;
  finally
    BitmapDestRGBA.Free;
  end;
end;

procedure TFLIFImage.DrawImage(DC: HDC; Rect: TRect);
var
  BitmapInfo: TBitmapInfo;
  BufferDC: HDC;
  BufferBits: Pointer;
  OldBitmap, BufferBitmap: HBITMAP;
  W, H: Integer;
begin
  if Rect.IsEmpty then
    Exit;

  W := Max(0, Min(Self.Width, Rect.Width));
  H := Max(0, Min(Self.Height, Rect.Height));

  if ((FImageType = fitRGBA) or (FImageType = fitHDR)) then
  begin
    // Draw image with alpha channel

    if (W = Width) and (H = Height) then
    begin
      // ... without stretching

      // Configuring the draw buffer
      FillChar(BitmapInfo, SizeOf(TBitmapInfo), 0);
      with BitmapInfo.bmiHeader do
      begin
        biSize := SizeOf(TBitmapInfoHeader);
        biCompression := BI_RGB;
        biPlanes := 1;
        biBitCount := 32;
        biWidth := W;
        biHeight := -Integer(H);
      end;

      // Create draw buffer
      BufferDC := CreateCompatibleDC(0);
      BufferBitmap := CreateDIBSection(BufferDC, BitmapInfo, DIB_RGB_COLORS, BufferBits, 0, 0);
      if (BufferBitmap = 0) or (BufferBits = nil) then
      begin
        RaiseLastOSError;
      end;

      try
        OldBitmap := SelectObject(BufferDC, BufferBitmap);
        try
          // Draw background image
          BitBlt(BufferDC, 0, 0, W, H, DC, Rect.Left, Rect.Top, SRCCOPY);

          // Blend background and foreground image
          AlphaBlendBGRA(BufferBits, FData, Width * Height, True);

          // Drawing resulting image
          BitBlt(DC, Rect.Left, Rect.Top, W, H, BufferDC, 0, 0, SRCCOPY);
        finally
          SelectObject(BufferDC, OldBitmap);
        end;
      finally
        if BufferBitmap <> 0 then
          DeleteObject(BufferBitmap);

        if BufferDC <> 0 then
          DeleteDC(BufferDC);
      end;
    end
    else
    begin
      StretchImageAlpha(DC, Rect);
    end;
  end
  else
  begin
    SetStretchBltMode(DC, FStretchType);
    StretchBlt(DC, Rect.Left, Rect.Top, Rect.Width, Rect.Height, FCanvas.Handle,
      0, 0, Width, Height, SRCCOPY);
  end;
end;

procedure TFLIFImage.Draw(ACanvas: TCanvas; const Rect: TRect);
begin
  if Empty then
    Exit;

  DrawImage(ACanvas.Handle, Rect);
end;

function TFLIFImage.GetEmpty: Boolean;
begin
  Result := not Assigned(FData);
end;

function TFLIFImage.GetHeight: Integer;
begin
  if Empty then
    Result := 0
  else
    Result := Abs(FInfo.bmiHeader.biHeight);
end;

function TFLIFImage.GetScanLine(Y: Integer): PByte;
begin
  Result := nil;

  if (Y >= 0) and (Y < Height) then
  begin
    Result := @FData[FRowSize * NativeUInt(Y)];
  end;
end;

function TFLIFImage.GetTransparent: Boolean;
begin
  Result := not Empty and (Channels = 4);
end;

function TFLIFImage.GetWidth: Integer;
begin
  if Empty then
    Result := 0
  else
    Result := Abs(FInfo.bmiHeader.biWidth);
end;

procedure TFLIFImage.SetImageTypeAndInitStruct(AChannels, ADepth: Byte;
  const APaletteSize, AWidth, AHeight: NativeUInt);
var
  PixelNotSupported: Boolean;
begin
  PixelNotSupported := True;

  case AChannels of
    1:
      if (ADepth = 8) then
      begin
        if (APaletteSize = 0) then
          FImageType := fitGRAY
        else
          FImageType := fitPALETTE;

        PixelNotSupported := False;
      end;

    3:
      if (ADepth = 8) and (APaletteSize = 0) then
      begin
        FImageType := fitRGB;

        PixelNotSupported := False;
      end
      else if (ADepth = 8) and (APaletteSize <> 0) then
      begin
        FImageType := fitPALETTE;
        AChannels := 1;

        PixelNotSupported := False;
      end;

    4:
      if (ADepth = 8) and (APaletteSize = 0) then
      begin
        FImageType := fitRGBA;

        PixelNotSupported := False;
      end
      else if (ADepth = 16) and (APaletteSize = 0) then
      begin
        FImageType := fitHDR;

        PixelNotSupported := False;
      end
      else if (ADepth = 8) and (APaletteSize > 0) then
      begin
        FImageType := fitPALETTE;
        AChannels := 1;

        PixelNotSupported := False;
      end;
  end;

  if PixelNotSupported then
  begin
    raise Exception.Create(
      Format('TFLIFImage is not support pixel format: Channels: %d, Depth: %d, Palette: %d',
      [AChannels, ADepth, APaletteSize])
    );
  end
  else
  begin
    FChannels := AChannels;
    FDepth := ADepth;
    FPaletteExist := (APaletteSize > 0) and (FImageType = fitPALETTE);
    FPaletteCount := APaletteSize;

    if ADepth = 8 then
    begin
      FRowSize := BytesPerScanline(AWidth, FChannels * FDepth, 32);
      FPixelRowSize := (AWidth * FChannels * Depth) div 8;
      FExtraRowSize := 0;

      FDataSize := FRowSize * AHeight;
      FExtraDataSize := 0;
    end
    else
    begin
      FDataSize := (FChannels * 8 * AWidth * AHeight) div 8;
      FExtraDataSize := (FChannels * FDepth * AWidth * AHeight) div 8;

      FRowSize := (AWidth * AChannels * 8) div 8;
      FExtraRowSize := (AWidth * AChannels * ADepth) div 8;
    end;

    if Assigned(FData) then
      FreeMemory(FData);

    if Assigned(FExtraData) then
      FreeMemory(FExtraData);

    FData := GetMemory(FDataSize);
    FillChar(FData^, FDataSize, 0);
    FExtraData := GetMemory(FExtraDataSize);
    FillChar(FExtraData^, FExtraDataSize, 0);

    if FImageType = fitGRAY then
      FPaletteCount := 256;

    FillChar(FInfo, SizeOf(TBitmapInfoEx), 0);
    FInfo.bmiHeader.biSize := SizeOf(BITMAPINFOHEADER);
    FInfo.bmiHeader.biWidth := Integer(AWidth);
    FInfo.bmiHeader.biHeight := -Integer(AHeight);
    FInfo.bmiHeader.biPlanes := 1;
    FInfo.bmiHeader.biBitCount := 8 * AChannels;
    FInfo.bmiHeader.biCompression := BI_RGB;
    FInfo.bmiHeader.biSizeImage := 0;
    FInfo.bmiHeader.biClrUsed := FPaletteCount;
  end;
end;

procedure TFLIFImage.SetStretchType(const Value: Cardinal);
begin
  FStretchType := Value;
  if (FStretchType < 1) or (FStretchType > 4) then
    FStretchType := 1;
end;

procedure TFLIFImage.LoadPixelsFromFlifImage(Image: TFLIFImagePointer);
var
  y: NativeUInt;
  RowData: PByte;
  RowDataSize: NativeUInt;
begin
  SetImageTypeAndInitStruct(
    flif_image_get_nb_channels(Image),
    flif_image_get_depth(Image),
    {$ifdef flif_master}flif_image_get_palette_size(Image){$else}0{$endif},
    flif_image_get_width(Image),
    flif_image_get_height(Image)
  );

  case ImageType of
    fitRGB:
      begin
        RowDataSize := (Width * 4 * Depth) div 8;
        RowData := GetMemory(RowDataSize);
        try
          for y := 0 to Height - 1 do
          begin
            flif_image_read_row_RGBA8(Image, y, RowData, RowDataSize);
            BGRA2RGB(RowData, RowData, Width);
            Move(RowData^, ScanLine[y]^, FPixelRowSize);
          end;
        finally
          FreeMemory(RowData);
        end;
      end;

    fitRGBA:
      begin
        for y := 0 to Height - 1 do
        begin
          flif_image_read_row_RGBA8(Image, y, Pointer(@FData[FRowSize * y]), FRowSize);
        end;

        BGRA2RGBA(FData, FData, Width * Height);
      end;

    fitHDR:
      begin
        // Load from FLIF rrggbbaa data
        for y := 0 to Height - 1 do
        begin
          flif_image_read_row_RGBA16(Image, y, Pointer(@FExtraData[FExtraRowSize * y]), FExtraRowSize);
        end;

        // Convert rrggbbaa to bbggrraa
        BGRA2RGBA16(FExtraData, FExtraData, Width * Height);

        // Convert rrggbbaa to rgba (64 bits > 32 bits)
        RowDataSize := FExtraDataSize;
        RowData := GetMemory(RowDataSize);
        try
          Move(FExtraData^, RowData^, RowDataSize);
          RGBA16toRGBA8(RowData, RowData, Width * Height);
          Move(RowData^, FData^, FDataSize);
        finally
          FreeMemory(RowData);
        end;
      end;

    {$ifdef flif_master}
    fitGRAY:
      begin
        for y := 0 to Height - 1 do
        begin
          flif_image_read_row_GRAY8(Image, y, ScanLine[y], FPixelRowSize);
        end;

        Move(PaletteGray.palPalEntry[0].peRed, FInfo.bmiColors[0].rgbBlue, 256 * 4);
      end;

    fitPALETTE:
      begin
        for y := 0 to Height - 1 do
        begin
          flif_image_read_row_PALETTE8(Image, y, ScanLine[y], FPixelRowSize);
        end;

        flif_image_get_palette(Image, Pointer(@FPalette[0].B));
        RGBA2BGRA(Pointer(@FPalette[0].B), Pointer(@FPalette[0].B), FPaletteCount);
      end;
    {$endif}

  else
    raise Exception.Create('Image type not realized!');
  end;

  CreateCanvas;
end;

procedure TFLIFImage.LoadFromClipboardFormat(AFormat: Word; AData: NativeUInt;
  APalette: HPALETTE);
begin
  raise Exception.Create('Not supported!');
end;

procedure TFLIFImage.LoadFromStream(Stream: TStream);
var
  Decoder: TFLIFDecoder;
  Data: PByte;
  Size: NativeUInt;
  DecodeError: Integer;
  Image: TFLIFImagePointer;
begin
  inherited;
  Clear;

  Size := NativeUInt(Stream.Size - Stream.Position);

  Decoder := flif_create_decoder;
  Data := GetMemory(Size);
  try
    // Applies custom decoding settings
    FDecoder.Apply(Decoder);

    // Decoding flif image data from stream
    Stream.Read(Data^, Size);
    DecodeError := flif_decoder_decode_memory(Decoder, Data, Size);
    if DecodeError <> 1 then
      raise Exception.Create('Decoding error: ' + IntToStr(DecodeError));

    // Get first only image
    // todo: Get multiple images, if available.
    Image := flif_decoder_get_image(Decoder, 0);
    if not Assigned(Image) then
      raise Exception.Create('Error get image from decoder');

    LoadPixelsFromFlifImage(Image);
  finally
//    flif_destroy_image(Image);
    flif_destroy_decoder(Decoder);
    FreeMemory(Data);
  end;
end;

procedure TFLIFImage.SaveToClipboardFormat(var AFormat: Word;
  var AData: NativeUInt; var APalette: HPALETTE);
begin
  raise Exception.Create('Not supported!');
end;

function TFLIFImage.SavePixelsToFlif: TFLIFImagePointer;
var
  NewData: PByte;
  y, NewRowSize, W, H: NativeUInt;
begin
  Result := nil;

  case FImageType of
    fitRGB:
      begin
        W := NativeUInt(Width);
        H := NativeUInt(Height);
        NewRowSize := FPixelRowSize + W;
        NewData := GetMemory(NewRowSize * H);
        try
          if FRowSize = FPixelRowSize then
            BGR2RGB(FData, NewData, FDataSize)
          else
            BGR2RGBa_(FData, NewData, Width, Height, FRowSize);

          Result := flif_import_image_RGB(Width, Height, NewData, FRowSize);
        finally
          FreeMemory(NewData);
        end;
      end;

    fitRGBA:
      begin
        Result := flif_create_image(Width, Height);
        NewData := GetMemory(FDataSize);
        try
          BGRA2RGBA(FData, NewData, Width * Height);

          for y := 0 to Height - 1 do
          begin
            flif_image_write_row_RGBA8(Result, y, @NewData[FRowSize * y],
              FRowSize);
          end;
        finally
          FreeMemory(NewData);
        end;
      end;

    fitHDR:
      begin
        Result := flif_create_image_HDR(Width, Height);
        NewData := GetMemory(FExtraDataSize);
        try
          // Convert bbggrraa to rrggbbaa
          BGRA2RGBA16(FExtraData, NewData, Width * Height);

          // Write to FLIF
          for y := 0 to Height - 1 do
          begin
            flif_image_write_row_RGBA16(Result, y, @NewData[FExtraRowSize * y],
              FExtraRowSize);
          end;
        finally
          FreeMemory(NewData);
        end;
      end;

    {$ifdef flif_master}
    fitGRAY:
      begin
        Result := flif_create_image_GRAY(Width, Height);
        for y := 0 to Height - 1 do
        begin
          flif_image_write_row_GRAY8(Result, y, @ScanLine[y][0], FPixelRowSize);
        end;
      end;

    fitPALETTE:
      begin
        //todo: Реализовать сохранение c использованием palette
//        raise Exception.Create('Error save flif image with palette. This is not implemented.');

        NewData := GetMemory(Width * Height);
        try
          for y := 0 to Height - 1 do
          begin
            Move(ScanLine[y]^, NewData[NativeUInt(Width) * y], Width);
          end;

          Result := flif_import_image_PALETTE(Width, Height, NewData, Width);
        finally
          FreeMemory(NewData);
        end;

        NewData := GetMemory(FPaletteCount * 4);
        try
          FillChar(NewData^, FPaletteCount * 4, 0);
          BGRA2RGBA(@FPalette, NewData, FPaletteCount);
          flif_image_set_palette(Result, NewData, FPaletteCount);
        finally
          FreeMemory(NewData);
        end;
      end;
    {$endif}
  end;
end;

procedure TFLIFImage.SaveToStream(Stream: TStream);
var
  Buffer: Pointer;
  BufferSize: NativeUInt;
  Encoder: TFLIFEncoder;
  EncodeState, WriteSize: Int32;
  Image: TFLIFImagePointer;
begin
  inherited;
  if Empty then
    raise Exception.Create('Image is null');

  if FTempExist and not FEncoder.IsChange then
  begin
    FTemp.Position := 0;
    Stream.CopyFrom(FTemp, FTemp.Size);
    Exit;
  end;

  Encoder := flif_create_encoder;
  try
    // Applying encoder settings
    FEncoder.Apply(Encoder);

    // Create image and store pixel info
    Image := SavePixelsToFlif;
    if not Assigned(Image) then
      raise Exception.Create('TFlifImage can not save in this format');
    try
      // Encoding image
      flif_encoder_add_image(Encoder, Image);
      EncodeState := flif_encoder_encode_memory(Encoder, Buffer, BufferSize);

      if EncodeState = 1 then
      begin
        try
          FTemp.Position := 0;
          FTemp.Size := BufferSize;
          FTemp.Write(Buffer^, BufferSize);
          FTempExist := True;

          WriteSize := Stream.Write(Buffer^, BufferSize);
          if NativeUInt(WriteSize) <> BufferSize then
            raise Exception.Create('Error write FLIF file');
        finally
          flif_free_memory(Buffer);
        end;
      end
      else
        raise Exception.Create('Error encoding flif image.');
    finally
      flif_destroy_image(Image);
    end;
  finally
    flif_destroy_encoder(Encoder);
  end;
end;

procedure TFLIFImage.SetHeight(Value: Integer);
begin
  Clear;
end;

procedure TFLIFImage.SetWidth(Value: Integer);
begin
  Clear;
end;

(*

    Copy image from TPngImage

*)
{$ifdef flif_include_png}
function GetChannelNumberPNG(ColorType: Byte): NativeUInt;
begin
  case ColorType of
    COLOR_GRAYSCALE,
    COLOR_PALETTE:
      Result := 1;

    COLOR_RGB:
      Result := 3;

    COLOR_GRAYSCALEALPHA:
      Result := 2;

    COLOR_RGBALPHA:
      Result := 4;
  else
    Result := 0;
  end;
end;

function GetPixelSizePNG(ColorType, BitDepth: Byte): NativeUInt; inline;
begin
  Result := (BitDepth * GetChannelNumberPNG(ColorType)) div 8;
end;

function GetPixelsSizePNG(Pixels: NativeUInt; ColorType,
  BitDepth: Byte): NativeUInt; inline;
begin
  Result := GetPixelSizePNG(ColorType, BitDepth) * Pixels;
end;

procedure TFLIFImage.WriteDataFromPNG(Image: TPngImage);
var
  y: NativeUInt;
begin
  case FImageType of
    fitRGB, fitGRAY, fitPALETTE:
      begin
        for y := 0 to Image.Height - 1 do
        begin
          Move(Image.Scanline[y]^, ScanLine[y]^, FPixelRowSize);
        end;
      end;

    fitRGBA:
      begin
        for y := 0 to Image.Height - 1 do
        begin
          RGB2RGBA(Image.Scanline[y], ScanLine[y], Image.AlphaScanline[y],
            Image.Width);
        end;
      end;

    fitHDR:
      begin
        for y := 0 to Image.Height - 1 do
        begin
          RGB2RGBA16_A8(Image.Scanline[y], Image.ExtraScanline[y],
            @FExtraData[y * FExtraRowSize], Image.AlphaScanline[y], Image.Width
          );

          RGB2RGBA(Image.Scanline[y], ScanLine[y], Image.AlphaScanline[y],
            Image.Width);
        end;
      end;
  end;
end;

procedure TFLIFImage.AssignFromPng(Image: TPngImage);
var
  PalSize: NativeUInt;
  PaletteList: array[Byte] of TPaletteEntry;
begin
  if Image.Empty then
    raise Exception.Create('TPngImage is empty!');

  PalSize := 0;
  if (Image.Header.ColorType = COLOR_PALETTE) then
  begin
    PalSize := GetPaletteEntries(Image.Palette, 0, 256, PaletteList[0]);
  end;

  SetImageTypeAndInitStruct(
    GetChannelNumberPNG(Image.Header.ColorType),
    Image.Header.BitDepth,
    PalSize,
    Image.Width, Image.Height
  );

  if PaletteExist then
  begin
    Move(PaletteList[0].peRed, FPalette[0].B, FPaletteCount * 4);
    BGRA2RGBA(Pointer(@FPalette[0].B), Pointer(@FPalette[0].B), FPaletteCount);
    RGBAsetAlpha(Pointer(@FPalette[0].B), 255, FPaletteCount);
  end;

  WriteDataFromPNG(Image);

  CreateCanvas;
end;

procedure TFLIFImage.AssignToPng(Image: TPngImage);
var
  Png: TPngImage;
begin
  Png := GetPng;
  try
    Image.Assign(Png);
  finally
    Png.Free;
  end;
end;

function TFLIFImage.GetPNGColor: Cardinal;
const
  COLOR_NOT_VALID = 9999999;
begin
  Result := COLOR_NOT_VALID;

  case FImageType of
    fitRGB:
      Result := COLOR_RGB;

    fitRGBA:
      Result := COLOR_RGBALPHA;
    fitGRAY:
      Result := COLOR_GRAYSCALE;

    fitPALETTE:
      Result := COLOR_PALETTE
  end;
end;

function TFLIFImage.GetPng: TPngImage;
var
  Image: TPngImage;
  y: Integer;
  Data, Alpha: Pointer;
  LogPal: TMaxLogPalette;
begin
  Image := TPngImage.CreateBlank(GetPNGColor, FDepth, Width, Height);
  try
    case FImageType of
      fitGRAY,
      fitPALETTE,
      fitRGB:
        begin
          for y := 0 to Height - 1 do
          begin
            Move(ScanLine[y]^, Image.Scanline[y]^, FPixelRowSize);
          end;
        end;

      fitRGBA:
        begin
          Data := GetMemory(Width * 3);
          Alpha := GetMemory(Width);
          try
            for y := 0 to Height - 1 do
            begin
              BGRA2BGRandA(ScanLine[y], Data, Alpha, Width);

              Move(Data^, Image.Scanline[y]^, Width * 3);
              Move(Alpha^, Image.AlphaScanline[y]^, Width);
            end;
          finally
            FreeMemory(Data);
            FreeMemory(Alpha);
          end;
        end;
      fitHDR: ;
    end;

    if FImageType = fitPALETTE then
    begin
      LogPal.palVersion := $300;
      LogPal.palNumEntries := FPaletteCount;
      RGBA2BGRA(@FPalette[0].B, @LogPal.palPalEntry[0].peRed, FPaletteCount);
      Image.Palette := CreatePalette(@LogPal);
    end;

  finally
    Result := Image;
  end;
end;
{$endif}

{$ifdef flif_include_jpeg}
procedure TFLIFImage.AssignFromJpeg(Image: TJPEGImage);
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  try
    Bitmap.Assign(Image);
    AssignFromBitmap(Bitmap);
  finally
    Bitmap.Free;
  end;
end;

procedure TFLIFImage.AssignToJpeg(Image: TJPEGImage);
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  try
    GetBitmap(Bitmap);
    Image.Assign(Bitmap);
  finally
    Bitmap.Free;
  end;
end;
{$endif}

{$ifdef flif_include_bitmap}
function TFLIFImage.GetBitmap(Bitmap: TBitmap): TBitmap;
var
  Image: TBitmap;
  y: Integer;
  MaxPal: TMaxLogPalette;
begin
  Image := Bitmap;
  if not Assigned(Image) then
    Image := TBitmap.Create;
  try
    Image.Transparent := False;
    Image.SetSize(Width, Height);
    case FImageType of
      fitRGB:
          Image.PixelFormat := pf24bit;

      fitRGBA:
        Image.PixelFormat := pf32bit;

      fitHDR:
        raise Exception.Create('Error Message');

      fitPALETTE,
      fitGRAY:
        Image.PixelFormat := pf8bit;
    end;

    if (FImageType = fitGRAY) or (FImageType = fitPALETTE) then
    begin
      if PaletteExist then
      begin
        MaxPal.palVersion := $300;
        MaxPal.palNumEntries := FPaletteCount;
        BGRA2RGBA(@FPalette[0].B, @MaxPal.palPalEntry[0].peRed, FPaletteCount);

        Image.Palette := CreatePalette(@MaxPal);
      end
      else
      begin
        Image.Palette := CreatePalette(@PaletteGray);
      end;
    end;

    if FImageType = fitRGBA then
    begin
      Image.Canvas.Draw(0, 0, Self);
    end
    else
    begin
      for y := 0 to Height - 1 do
      begin
        Move(ScanLine[y]^, Image.ScanLine[y]^, FPixelRowSize);
      end;
    end;
  finally
    Result := Image;
  end;
end;

procedure TFLIFImage.AssignFromBitmap(Bitmap: TBitmap);
var
  Channels: Byte;
  y: Integer;
  LogPal: TMaxLogPalette;
  NumEntries: UINT;
begin
  Channels := 0;
  NumEntries := 0;
  case Bitmap.PixelFormat of
    pf8bit:
      Channels := 1;
    pf24bit:
      Channels := 3;
    pf32bit:
      Channels := 4;
  end;

  if (Channels = 1) then
  begin
    // Get palette from bitmap and check is gray palette
    NumEntries := GetPaletteEntries(Bitmap.Palette, 0, 256, LogPal.palPalEntry[0]);
    if IsGrayScalePalette(@LogPal.palPalEntry, NumEntries) then
      NumEntries := 0;
  end;

  SetImageTypeAndInitStruct(Channels, 8, NumEntries, Bitmap.Width, Bitmap.Height);
  for y := 0 to Height - 1 do
  begin
    Move(Bitmap.ScanLine[y]^, ScanLine[y]^, FPixelRowSize);
  end;

  if FImageType = fitRGBA then
    RGBAsetAlpha(FData, 255, Width * Height);

  if FPaletteExist then
  begin
    Move(LogPal.palPalEntry[0].peRed, FPalette[0].B, FPaletteCount * 4);
    RGBA2BGRA(@FPalette[0].B, @FPalette[0].B, FPaletteCount);
    RGBAsetAlpha(@FPalette[0].B, 255, FPaletteCount);
  end;

  CreateCanvas;
end;

procedure TFLIFImage.AssignToBitmap(Bitmap: TBitmap);
begin
  GetBitmap(Bitmap)
end;
{$endif}

{ TDecoderSettings }

procedure TDecoderSettings.Apply(Decoder: TFLIFDecoder);
begin
  flif_decoder_set_quality(Decoder, FQuality);
  flif_decoder_set_crc_check(Decoder, Integer(FCrcCheck));
  flif_decoder_set_scale(Decoder, Cardinal(FScale));

  if FResizeChange then
    flif_decoder_set_resize(Decoder, FResize.cx, FResize.cy);

  if FFitChange then
    flif_decoder_set_fit(Decoder, FFit.cx, FFit.cy);
end;

constructor TDecoderSettings.Create;
begin
  Default;
end;

procedure TDecoderSettings.Default;
begin
  FQuality := 100;
  FCrcCheck := False;
  FScale := 1;
  FFitChange := False;
  FResizeChange := False;
  FFit := TSize.Create(0, 0);
  FResize := TSize.Create(0, 0);
end;

procedure TDecoderSettings.SetFit(const Value: TSize);
begin
  if (FFit.cx <> Value.cx) or (FFit.cy <> Value.cy) then
  begin
    FFitChange := True;
    FFit := Value;
  end;
end;

procedure TDecoderSettings.SetResize(const Value: TSize);
begin
  if Value.Subtract(Value).IsZero then
  begin
    FResizeChange := True;
    FResize := Value;
  end;
end;

procedure TDecoderSettings.SetScale(const Value: NativeUInt);
begin
  FScale := Value;
  if (Value and (Value - 1)) <> 0 then
    FScale := 1;
end;

{ TEncoderSettings }

procedure TEncoderSettings.Apply(Encoder: TFLIFEncoder);
begin
  FChange := False;

  if FInterlacedChange then
    flif_encoder_set_interlaced(Encoder, Cardinal(FInterlaced));

  if FLearnRepeatChange then
    flif_encoder_set_learn_repeat(Encoder, FLearnRepeat);

  if FAutoColorBucketsChange then
    flif_encoder_set_auto_color_buckets(Encoder, Cardinal(FAutoColorBuckets));

  if FPaletteSizeChange then
    flif_encoder_set_palette_size(Encoder, FPaletteSize);

  if FLookbackChange then
    flif_encoder_set_lookback(Encoder, Integer(FLookback));

  if FDivisorChange then
    flif_encoder_set_divisor(Encoder, FDivisor);

  if FMinSizeChange then
    flif_encoder_set_min_size(Encoder, FMinSize);

  if FSplitThresholdChange then
    flif_encoder_set_split_threshold(Encoder, FSplitThreshold);

  if FChanceCutoffChange then
    flif_encoder_set_chance_cutoff(Encoder, FChanceCutoff);

  if FChanceAlphaChange then
    flif_encoder_set_chance_alpha(Encoder, FChanceAlpha);

  if FCrcCheckChange then
    flif_encoder_set_crc_check(Encoder, Cardinal(FCrcCheck));

  if FChannelCompactChange then
    flif_encoder_set_channel_compact(Encoder, Cardinal(FChannelCompact));

  if FYcocgChange then
    flif_encoder_set_ycocg(Encoder, Cardinal(FYcocg));

  if FFrameShapeChange then
    flif_encoder_set_frame_shape(Encoder, Cardinal(FFrameShape));

  if FLossyChange then
    flif_encoder_set_lossy(Encoder, Integer(FLossy));
end;

constructor TEncoderSettings.Create;
begin
  Default;
  FChange := False;
end;

procedure TEncoderSettings.Default;
begin
  FChange := True;
  FInterlaced := True;
  FInterlacedChange := False;
  FLearnRepeat := 2;
  FLearnRepeatChange := False;
  FAutoColorBuckets := True;
  FAutoColorBucketsChange := False;
  FPaletteSize := 512;
  FPaletteSizeChange := False;
  FLookback := True;
  FLookbackChange := False;
  FDivisor := 30;
  FDivisorChange := False;
  FMinSize := 50;
  FMinSizeChange := False;
  FSplitThreshold := 64;
  FSplitThresholdChange := False;
  FAlphaZeroLossless := False;
  FAlphaZeroLosslessChange := False;
  FChanceCutoff := 2;
  FChanceCutoffChange := False;
  FChanceAlpha := 19;
  FChanceAlphaChange := False;
  FCrcCheck := True;
  FCrcCheckChange := False;
  FChannelCompact := True;
  FChannelCompactChange := False;
  FYcocg := True;
  FYcocgChange := False;
  FFrameShape := True;
  FFrameShapeChange := False;
  FLossy := 0;
  FLossyChange := False;
end;

procedure TEncoderSettings.GetAlphaZeroLossless(const Value: Boolean);
begin
  FAlphaZeroLossless := Value;
  FAlphaZeroLossless := False;  //todo: ??
  FAlphaZeroLosslessChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetAutoColorBuckets(const Value: Boolean);
begin
  FAutoColorBuckets := Value;
  FAutoColorBucketsChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetChanceAlpha(const Value: Int32);
begin
  FChanceAlpha := Value;
  FChanceAlphaChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetChanceCutoff(const Value: Int32);
begin
  FChanceCutoff := Value;
  FChanceCutoffChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetChannelCompact(const Value: Boolean);
begin
  FChannelCompact := Value;
  FChannelCompactChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetCrcCheck(const Value: Boolean);
begin
  FCrcCheck := Value;
  FCrcCheckChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetDivisor(const Value: Int32);
begin
  FDivisor := Value;
  FDivisorChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetFrameShape(const Value: Boolean);
begin
  FFrameShape := Value;
  FFrameShapeChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetInterlaced(const Value: Boolean);
begin
  FInterlaced := Value;
  FInterlacedChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetLearnRepeat(const Value: UInt32);
begin
  FLearnRepeat := Value;
  FLearnRepeatChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetLookback(const Value: Boolean);
begin
  FLookback := Value;
  FLookbackChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetLossy(const Value: TFlifCodeQuality);
begin
  FLossy := Value;
  FLossyChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetMinSize(const Value: Int32);
begin
  FMinSize := Value;
  FMinSizeChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetPaletteSize(const Value: UInt32);
begin
  FPaletteSize := Value;
  FPaletteSizeChange := True;
  if FPaletteSize > 512 then
    FPaletteSize := 512;
  FChange := True;
end;

procedure TEncoderSettings.SetSplitThreshold(const Value: Int32);
begin
  FSplitThreshold := Value;
  FSplitThresholdChange := True;
  FChange := True;
end;

procedure TEncoderSettings.SetYcocg(const Value: Boolean);
begin
  FYcocg := Value;
  FYcocgChange := True;
  FChange := True;
end;

initialization
  TPicture.RegisterFileFormat('FLIF', 'FLIF is a lossless image format based on MANIAC compression. ', TFLIFImage);

finalization
  TPicture.UnregisterGraphicClass(TFLIFImage);

end.
