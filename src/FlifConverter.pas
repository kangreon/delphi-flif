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

unit FlifConverter;

interface

{$I src/flif.inc}

uses
  SysUtils, Graphics, FlifImage,
  {$ifdef flif_include_png}
    PngImage,
  {$endif}
  {$ifdef flif_include_jpeg}
  Jpeg,
  {$endif}
  Classes;

type
  TImageType = (itNone, itFLIF, itPNG, itJPEG, itBMP);

  TFlifConverter = class(TThread)
  private
    FFileName: string;
    FFlif: TFLIFImage;
    FImage: TGraphic;
    FSourceImage: TImageType;
    FErrorExist: Boolean;
    FErrorText: string;
    FOriginalSize: Int64;
    FSaveFileSize: Int64;
    FSize: Single;
    function GetImageType: TImageType;
    function GetFileSize(const FileName: string): Int64;
  protected
    procedure Execute; override;

  public
    constructor Create(FileName: string);

    class function IsValidFileName(const FileName: string): Boolean;

    property SourceImage: TImageType read FSourceImage;
    property Size: Single read FSize;
    property Flif: TFLIFImage read FFlif;

    property ErrorExist: Boolean read FErrorExist;
    property ErrorText: string read FErrorText;
  end;

implementation

{ TFlifConverter }

constructor TFlifConverter.Create(FileName: string);
begin
  FFileName := FileName;
  FSourceImage := itNone;
  FErrorExist := False;
  FSize := 0;
  inherited Create(True);
end;

function TFlifConverter.GetImageType: TImageType;
begin
  Result := itNone;

  FFlif := TFLIFImage.Create;
  try
    try
      FFlif.LoadFromFile(FFileName);
      if not FFlif.Empty then
        Result := itFLIF;
    except
    end;
  finally
    if Result = itNone then
      FFlif.Free;
  end;

  {$ifdef flif_include_png}
  if Result = itNone then
  begin
    FImage := TPngImage.Create;
    try
      try
        FImage.LoadFromFile(FFileName);
        if not FImage.Empty then
          Result := itPNG;
      except
      end;
    finally
      if Result = itNone then
        FImage.Free;
    end;
  end;
  {$endif}

  {$ifdef flif_include_jpeg}
  if Result = itNone then
  begin
    FImage := TJPEGImage.Create;
    try
      try
        FImage.LoadFromFile(FFileName);
        if not FImage.Empty then
          Result := itJPEG;
      except
      end;
    finally
      if Result = itNone then
        FImage.Free;
    end;
  end;
  {$endif}

  if Result = itNone then
  begin
    FImage := TBitmap.Create;
    try
      try
        FImage.LoadFromFile(FFileName);
        if not FImage.Empty then
          Result := itBMP;
      except
      end;
    finally
      if Result = itNone then
        FImage.Free;
    end;
  end;
end;

class function TFlifConverter.IsValidFileName(const FileName: string): Boolean;
var
  E: string;
begin
  E := AnsiUpperCase(ExtractFileExt(FileName));
  Result := {$ifdef flif_include_png}(E = '.PNG') or {$endif}(E = '.FLIF') or (E = '.JPG') or (E = '.JPEG') or
    (E = '.BMP');
end;

function TFlifConverter.GetFileSize(const FileName: string): Int64;
var
  Stream: TFileStream;
begin
  Result := 0;
  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
    try
      Result := Stream.Size;
    finally
      Stream.Free;
    end;
  except

  end;
end;

procedure TFlifConverter.Execute;
var
  Png: TGraphic;
begin
  inherited;
  FSourceImage := GetImageType;
  FSaveFileSize := 0;

  FOriginalSize := GetFileSize(FFileName);

  case FSourceImage of
    itFLIF:
      begin
        {$ifdef flif_include_png}
        Png := TPngImage.Create;
        {$else}
        Png := TBitmap.Create;
        {$endif}
        try
          try
            Png.Assign(FFlif);
            Png.SaveToFile(FFileName + '.png');
            FSaveFileSize := GetFileSize(FFileName + '.png');
          except
            on E: Exception do
            begin
              FErrorExist := True;
              FErrorText := E.Message;
            end;
          end;
        finally
          Png.Free;

        end;
      end;
    itPNG,
    itJPEG,
    itBMP:
      begin
        FFlif := TFLIFImage.Create;
        try
          try
            FFlif.Assign(FImage);
            FFlif.SaveToFile(FFileName + '.flif');
            FSaveFileSize := GetFileSize(FFileName + '.flif');
          except
            on E: Exception do
            begin
              FErrorText := E.Message;
              FErrorExist := True;
            end;
          end;
        finally
        end;
      end;

  else
    begin
      FErrorExist := True;
      FErrorText := 'Source image not supported!';
    end;
  end;

  if (FOriginalSize <> 0) and (FSaveFileSize <> 0) then
  begin
    FSize := FSaveFileSize / FOriginalSize * 100;
  end;

end;

end.
