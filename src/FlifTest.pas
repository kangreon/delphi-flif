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

unit FlifTest;

interface

{$I src/flif.inc}

uses
  Classes, SysUtils, Graphics, flif, FlifImage, PngImage, Jpeg, IOUtils, Types;

type
  TFlifColor = (fcRGBA16, fcRGBA8, fcRGB, fcGRAY, fcPALETTE);

  TFlifTest = class
  private
    FErrorIndex: Integer;
    FErrorDescription: string;
    function ValidatePixelInformation: Int32;
    function ValidateMetadata: Integer;
    function GetRandomData(out Size: NativeUInt; const SetSize: NativeUInt = 0): PByte;
    function ValidatePalleteAndFrame: Integer;
    function ValidateImport: Integer;
    function ValidateRowReadWrite: Integer;
    function ValidateConvert: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    function Test: Boolean;

    property ErrorIndex: Integer read FErrorIndex;
    property ErrorDescription: string read FErrorDescription;
  end;

implementation

{ TFlifExample }

constructor TFlifTest.Create;
begin

end;

destructor TFlifTest.Destroy;
begin

  inherited;
end;

function TFlifTest.ValidateRowReadWrite: Integer;
var
  Image: TFLIFImagePointer;
  Data, DataOut: PByte;
  DataSize: NativeUInt;
  W: UInt32;
  Channels, Depth: UInt8;
begin
  Result := 0;

  W := 100;
  Channels := 4;
  Depth := 8;
  Data := GetRandomData(DataSize, W * Channels * (Depth div 8));
  DataOut := GetMemory(DataSize);
  try
    Image := flif_create_image(W, 1);
    try
      flif_image_write_row_RGBA8(Image, 0, Data, DataSize);

      FillChar(DataOut^, DataSize, 0);
      flif_image_read_row_RGBA8(Image, 0, DataOut, DataSize);

      if not CompareMem(Data, DataOut, DataSize) then
      begin
        Result := 41;
        Exit;
      end;
    finally
      flif_destroy_image(Image);
    end;
  finally
    FreeMemory(DataOut);
    FreeMemory(Data);
  end;

  W := 100;
  Channels := 4;
  Depth := 16;
  Data := GetRandomData(DataSize, W * Channels * (Depth div 8));
  DataOut := GetMemory(DataSize);
  try
    Image := flif_create_image_HDR(W, 1);
    try
      flif_image_write_row_RGBA16(Image, 0, Data, DataSize);

      FillChar(DataOut^, DataSize, 0);
      flif_image_read_row_RGBA16(Image, 0, DataOut, DataSize);

      if not CompareMem(Data, DataOut, DataSize) then
      begin
        Result := 42;
        Exit;
      end;
    finally
      flif_destroy_image(Image);
    end;
  finally
    FreeMemory(DataOut);
    FreeMemory(Data);
  end;

  {$ifdef flif_master}
  W := 100;
  Channels := 1;
  Depth := 8;
  Data := GetRandomData(DataSize, W * Channels * (Depth div 8));
  DataOut := GetMemory(DataSize);
  try
    Image := flif_create_image(W, 1);
    try
      flif_image_write_row_GRAY8(Image, 0, Data, DataSize);

      FillChar(DataOut^, DataSize, 0);
      flif_image_read_row_GRAY8(Image, 0, DataOut, DataSize);

      if not CompareMem(Data, DataOut, DataSize) then
      begin
        Result := 43;
        Exit;
      end;
    finally
      flif_destroy_image(Image);
    end;
  finally
    FreeMemory(DataOut);
    FreeMemory(Data);
  end;

  W := 100;
  Channels := 4;
  Depth := 8;
  Data := GetRandomData(DataSize, W * Channels * (Depth div 8));
  DataOut := GetMemory(DataSize);
  try
    Image := flif_create_image_PALETTE(W, 1);
    try
      flif_image_write_row_PALETTE8(Image, 0, Data, DataSize div 4);

      FillChar(DataOut^, DataSize, 0);
      flif_image_read_row_PALETTE8(Image, 0, DataOut, DataSize div 4);

      if not CompareMem(Data, DataOut, DataSize div 4) then
      begin
        Result := 44;
        Exit;
      end;
    finally
      flif_destroy_image(Image);
    end;
  finally
    FreeMemory(DataOut);
    FreeMemory(Data);
  end;
  {$endif}
end;

function TFlifTest.ValidateConvert: Integer;
const
  OUT_PATH: array of string = ['BMP-OUT', 'FLIF-OUT', 'JPEG-OUT', 'PNG-OUT'];

  FLIF2PNG: array of string = ['GRAY', 'PALETTE', 'RGB8', 'RGBA8'{, 'RGBA16'}];
  FLIF2FLIF: array of string = ['GRAY', 'PALETTE', 'RGB8', 'RGBA8', 'RGBA16'];
  FLIF2JPEG: array of string = ['GRAY', 'RGB8'];
  FLIF2BMP: array of string = ['GRAY', 'PALETTE', 'RGB8', 'RGBA8'{, 'RGBA16'}];

  PNG2FLIF: array of string = ['GRAY', 'PALETTE', 'RGB8', 'RGBA8', 'RGBA16'];
  JPEG2FLIF: array of string = ['GRAY'{загружает palette вместо gray}, 'RGB8'];
  BMP2FLIF: array of string = ['GRAY', 'PALETTE', 'RGB8', 'RGBA8'];
var
  Image: TFLIFImage;
  Png: TPngImage;
  Flif: TFLIFImage;
  Jpeg: TJPEGImage;
  Bmp: TBitmap;
  FilePath, SourcePath, DestPath, FileName, DirName: string;
  Files: TStringDynArray;
begin
  FilePath := ExtractFilePath(ParamStr(0));
  Result := 51;
  try
    Image := TFLIFImage.Create;
    Png := TPngImage.Create;
    Flif := TFLIFImage.Create;
    Jpeg := TJPEGImage.Create;
    Bmp := TBitmap.Create;
    try
      SourcePath := FilePath + 'FLIF\';

      /// FLIF - PNG

      for DirName in OUT_PATH do
      begin
        Files := TDirectory.GetFiles(FilePath + DirName + '\');
        for FileName in Files do
          DeleteFile(FileName);
        Files := TDirectory.GetFiles(FilePath + DirName + '\');
        if Length(Files) <> 0 then
        begin
          Result := 51;
          Exit;
        end;
      end;

      DestPath := FilePath + 'PNG-OUT\';
      for FileName in FLIF2PNG do
      begin
        Result := 52;
        Image.LoadFromFile(SourcePath + FileName + '.flif');

        Result := 53;
        Png.Assign(Image);

        Result := 54;
        Png.SaveToFile(DestPath + FileName + '.png');
      end;

      DestPath := FilePath + 'FLIF-OUT\';
      for FileName in FLIF2FLIF do
      begin
        Result := 55;
        Image.LoadFromFile(SourcePath + FileName + '.flif');

        Result := 56;
        Flif.Assign(Image);

        Result := 57;
        Flif.SaveToFile(DestPath + FileName + '.flif');
      end;

      DestPath := FilePath + 'JPEG-OUT\';
      for FileName in FLIF2JPEG do
      begin
        Result := 58;
        Image.LoadFromFile(SourcePath + FileName + '.flif');

        Result := 59;
        Jpeg.Assign(Image);

        Result := 60;
        Jpeg.SaveToFile(DestPath + FileName + '.jpeg');
      end;

      DestPath := FilePath + 'BMP-OUT\';
      for FileName in FLIF2BMP do
      begin
        Result := 61;
        Image.LoadFromFile(SourcePath + FileName + '.flif');

        Result := 62;
        Bmp.Assign(Image);

        Result := 63;
        Bmp.SaveToFile(DestPath + FileName + '.bmp');
      end;

      DestPath := FilePath + 'FLIF-OUT\';

      SourcePath := FilePath + 'PNG\';
      for FileName in PNG2FLIF do
      begin
        Result := 64;
        Png.LoadFromFile(SourcePath + FileName + '.png');

        Result := 65;
        Flif.Assign(Png);

        Result := 66;
        Flif.SaveToFile(DestPath + FileName + '_1.flif');
      end;

      SourcePath := FilePath + 'JPEG\';
      for FileName in JPEG2FLIF do
      begin
        Result := 67;
        Jpeg.LoadFromFile(SourcePath + FileName + '.jpeg');

        Result := 68;
        Flif.Assign(Jpeg);

        Result := 69;
        Flif.SaveToFile(DestPath + FileName + '_2.flif');
      end;

      SourcePath := FilePath + 'BMP\';
      for FileName in BMP2FLIF do
      begin
        Result := 70;
        Bmp.LoadFromFile(SourcePath + FileName + '.bmp');

        Result := 71;
        Flif.Assign(Bmp);

        Result := 72;
        Flif.SaveToFile(DestPath + FileName + '_3.flif');
      end;

    finally
      Image.Free;
      Png.Free;
      Flif.Free;
      Jpeg.Free;
      Bmp.Free;
    end;

    Result := 0;
  except

  end;
end;

function TFlifTest.ValidateImport: Integer;
var
  Image: TFLIFImagePointer;
  W, H: UInt32;
  Data: PByte;
  Channels, Depth: UInt8;
  DataSize: NativeUInt;

function ValidateImage: Integer;
begin
  Result := 0;

  if flif_image_get_width(Image) <> W then
  begin
    Result := 31;
    Exit;
  end;

  if flif_image_get_height(Image) <> H then
  begin
    Result := 32;
    Exit;
  end;

  if flif_image_get_nb_channels(Image) <> Channels then
  begin
    Result := 33;
    Exit;
  end;

  if flif_image_get_depth(Image) <> Depth then
  begin
    Result := 34;
    Exit;
  end;
end;

begin
  W := 100;
  H := 100;
  Channels := 4;
  Depth := 8;
  DataSize := W * H * Channels * (Depth div 8);
  Data := GetMemory(DataSize);
  try
    Image := flif_import_image_RGBA(W, H, Data, W * Channels * (Depth div 8));
    try
      Result := ValidateImage;
      if Result <> 0 then
      begin
        FErrorDescription := 'RGBA';
        Exit;
      end;
    finally
      flif_destroy_image(Image);
    end;
  finally
    FreeMemory(Data);
  end;

  W := 100;
  H := 100;
  Channels := 3;
  Depth := 8;
  DataSize := W * H * Channels * (Depth div 8);
  Data := GetMemory(DataSize);
  try
    Image := flif_import_image_RGB(W, H, Data, W * Channels * (Depth div 8));
    try
      Result := ValidateImage;
      if Result <> 0 then
      begin
        FErrorDescription := 'RGB';
        Exit;
      end;
    finally
      flif_destroy_image(Image);
    end;
  finally
    FreeMemory(Data);
  end;

  W := 100;
  H := 100;
  Channels := 1;
  Depth := 8;
  DataSize := W * H * Channels * (Depth div 8);
  Data := GetMemory(DataSize);
  try
    Image := flif_import_image_GRAY(W, H, Data, W * Channels * (Depth div 8));
    try
      Result := ValidateImage;
      if Result <> 0 then
      begin
        FErrorDescription := 'GRAY';
        Exit;
      end;
    finally
      flif_destroy_image(Image);
    end;
  finally
    FreeMemory(Data);
  end;

  {$ifdef flif_master}
  W := 100;
  H := 100;
  Channels := 4;
  Depth := 8;
  DataSize := W * H * Channels * (Depth div 8);
  Data := GetMemory(DataSize);
  try
    Image := flif_import_image_PALETTE(W, H, Data, W * Channels * (Depth div 8));
    try
      Result := ValidateImage;
      if Result <> 0 then
      begin
        FErrorDescription := 'PALETTE';
        Exit;
      end;
    finally
      flif_destroy_image(Image);
    end;
  finally
    FreeMemory(Data);
  end;
  {$endif}

end;

function TFlifTest.ValidatePalleteAndFrame: Integer;
var
  Image: TFLIFImagePointer;
  Data, DataOut: PByte;
  PixelCount, DataSize: NativeUInt;
  FrameDelay: UInt32;
begin
  Result := 0;

  {$ifdef flif_master}
  Image := flif_create_image_PALETTE(100, 100);
  Data := GetRandomData(DataSize, 256 * 4);
  DataOut := GetMemory(DataSize);
  PixelCount := DataSize div 4;
  try
    if flif_image_get_nb_channels(Image) <> 4 then
    begin
      Result := 25;
      Exit;
    end;

    if flif_image_get_palette_size(Image) <> 0 then
    begin
      Result := 21;
      Exit;
    end;

    flif_image_set_palette(Image, Data, PixelCount);
    if flif_image_get_palette_size(Image) <> PixelCount then
    begin
      Result := 22;
      Exit;
    end;

    flif_image_get_palette(Image, DataOut);

    if not CompareMem(Data, DataOut, DataSize) then
    begin
      Result := 23;
      Exit;
    end;

    FrameDelay := Random(200) + 200;
    flif_image_set_frame_delay(Image, FrameDelay);
    if flif_image_get_frame_delay(Image) <> FrameDelay then
    begin
      Result := 24;
      Exit;
    end;
  finally
    FreeMemory(DataOut);
    FreeMemory(Data);
    flif_destroy_image(Image);
  end;
  {$endif}
end;

function TFlifTest.ValidatePixelInformation: Int32;
var
  Image: TFLIFImagePointer;
  NumberChannels, Depth: Integer;
  W, H: UInt32;

function ValidateImage: Integer;
begin
  Result := 0;

  if flif_image_get_width(Image) <> W then
  begin
    Result := 1;
    FErrorDescription := Format('width: %d not %d', [flif_image_get_width(Image), W]);
    Exit;
  end;

  if flif_image_get_height(Image) <> H then
  begin
    Result := 2;
    FErrorDescription := Format('height: %d not %d', [flif_image_get_height(Image), H]);
    Exit;
  end;

  if flif_image_get_nb_channels(Image) <> NumberChannels then
  begin
    Result := 3;
    FErrorDescription := Format('nb_channels: %d not %d', [flif_image_get_nb_channels(Image), NumberChannels]);
    Exit;
  end;

  if flif_image_get_depth(Image) <> Depth then
  begin
    FErrorDescription := Format('depth: %d not %d', [flif_image_get_depth(Image), Depth]);
    Result := 4;
    Exit;
  end;
end;

begin
  // RGBA16
  W := Random(100) + 100;
  H := Random(100) + 100;
  NumberChannels := 4;
  Depth := 16;
  Image := flif_create_image_HDR(W, H);
  try
    Result := ValidateImage;
    if Result <> 0 then Exit;
  finally
    flif_destroy_image(Image);
  end;

  // RGBA
  W := Random(100) + 100;
  H := Random(100) + 100;
  NumberChannels := 4;
  Depth := 8;
  Image := flif_create_image(W, H);
  try
    Result := ValidateImage;
    if Result <> 0 then Exit;
  finally
    flif_destroy_image(Image);
  end;

  {$ifdef flif_master}
  // RGB
  W := Random(100) + 100;
  H := Random(100) + 100;
  NumberChannels := 3;
  Depth := 8;
  Image := flif_create_image_RGB(W, H);
  try
    Result := ValidateImage;
    if Result <> 0 then Exit;
  finally
    flif_destroy_image(Image);
  end;


  // GRAY
  W := Random(100) + 100;
  H := Random(100) + 100;
  NumberChannels := 1;
  Depth := 8;
  Image := flif_create_image_GRAY(W, H);
  try
    Result := ValidateImage;
    if Result <> 0 then Exit;
  finally
    flif_destroy_image(Image);
  end;

  // PALETTE
  W := Random(100) + 100;
  H := Random(100) + 100;
  NumberChannels := 4;
  Depth := 8;
  Image := flif_create_image_PALETTE(W, H);
  try
    Result := ValidateImage;
    if Result <> 0 then Exit;
  finally
    flif_destroy_image(Image);
  end;
  {$endif}
end;

function TFlifTest.GetRandomData(out Size: NativeUInt; const SetSize: NativeUInt): PByte;
var
  i: NativeUInt;
begin
  if SetSize = 0 then
    Size := Random(1000) + 1000
  else
    Size := SetSize;

  Result := GetMemory(Size);
  for i := 0 to Size - 1 do
  begin
    Result[i] := Byte(Random(256));
  end;
end;

function TFlifTest.ValidateMetadata: Integer;
var
  Image: TFLIFImagePointer;
  A: RawByteString;
  i: Integer;
  Data, DataOriginal: PByte;
  DataSize, DataSizeOriginal: NativeUInt;
begin
  Result := 0;
  for i := 0 to 10 do
  begin
    Image := flif_create_image(100, 100);
    try
        A := AnsiChar(Random(255) + 1) + AnsiChar(Random(255) + 1) +
          AnsiChar(Random(255) + 1) + AnsiChar(Random(255) + 1);

        DataOriginal := GetRandomData(DataSizeOriginal);
        try
          flif_image_set_metadata(Image, PAnsiChar(A), DataOriginal, DataSizeOriginal);
          flif_image_get_metadata(Image, PAnsiChar(A), Data, DataSize);

          if DataSize <> DataSizeOriginal then
          begin
            FErrorDescription := Format('"%s" %d x %d', [A, DataSize, DataSizeOriginal]);
            Result := 11;
            Exit;
          end;

          if not CompareMem(Data, DataOriginal, DataSize) then
          begin
            Result := 12;
            Exit;
          end;
        finally
          FreeMemory(DataOriginal);
          flif_image_free_metadata(Image, Data);
        end;
    finally
      flif_destroy_image(Image);
    end;
  end;
end;

function TFlifTest.Test: Boolean;
begin
  ///
  ///  Begin testing flif_common.h
  ///

  FErrorIndex := ValidatePixelInformation;
  Result := FErrorIndex = 0;
  if not Result then Exit;

  FErrorIndex := ValidateMetadata;
  Result := FErrorIndex = 0;
  if not Result then Exit;

  FErrorIndex := ValidatePalleteAndFrame;
  Result := FErrorIndex = 0;
  if not Result then Exit;

  FErrorIndex := ValidateImport;
  Result := FErrorIndex = 0;
  if not Result then Exit;

  FErrorIndex := ValidateRowReadWrite;
  Result := FErrorIndex = 0;
  if not Result then Exit;

  ///
  ///  End testing flif_common.h
  ///

  FErrorIndex := ValidateConvert;
  Result := FErrorIndex = 0;
  if not Result then Exit;
end;

end.
