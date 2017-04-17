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

unit main;

interface

{$I src/flif.inc}

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, flif, Vcl.ExtCtrls, FLIFImage, FlifTest,
  Vcl.ComCtrls, DragAndDrop, FlifConverter,
  {$ifdef flif_include_png}PngImage,{$endif}
  {$ifdef flif_include_jpeg}Vcl.Imaging.jpeg,{$endif}


  FlifImageUtils, ShellApi;
type
  TPanel = class(Vcl.ExtCtrls.TPanel, IDragDrop)
  private
    FDropTarget: TDropTarget;
    FLabel: TLabel;
    FConverter: TFlifConverter;
    FConverterExist: Boolean;
    FOnUpdate: TNotifyEvent;
    procedure ConverterTerminate(Sender: TObject);
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  public
    ImageType, Channels, Depth: string;

    function DropAllowed(const FileNames: array of string): Boolean;
    procedure Drop(const FileNames: array of string);
  protected
    property OnUpdate: TNotifyEvent read FOnUpdate write FOnUpdate;
  end;

  TFormTestFlif = class(TForm)
    ButtonTest: TButton;
    ImageBackground: TImage;
    ComboBoxName: TComboBox;
    CheckBoxSave: TCheckBox;
    CheckBoxStretch: TCheckBox;
    PanelDrop: TPanel;
    Image3: TImage;
    LabelLog: TLabel;
    Memo2: TMemo;
    ComboBoxFrom: TComboBox;
    ComboBoxTo: TComboBox;
    ButtonLoadAndSave: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    LabelAddress: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    LabelView: TLabel;
    procedure FormPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ButtonTestClick(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure CheckBoxStretchClick(Sender: TObject);
    procedure ButtonLoadAndSaveClick(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure LabelAddressClick(Sender: TObject);
    procedure LabelAddressMouseEnter(Sender: TObject);
    procedure LabelAddressMouseLeave(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  protected
    procedure CreateWnd; override;

  private
    FImageLeft: Integer;
    FImageTop: Integer;
    FImage: TFLIFImage;
    FFreq: Int64;
    FTimeSum: Double;
    FTimeCount: Integer;
    FBackgroundTop: Integer;
    procedure DropUpdate(Sender: TObject);
    function GetImageFromIndex(Index: Integer): TGraphic;

  end;

var
  FormTestFlif: TFormTestFlif;

function GetImageDescription(const Image: TGraphic): string;

implementation

{$R *.dfm}

function TFormTestFlif.GetImageFromIndex(Index: Integer): TGraphic;
begin
  Result := nil;

  case Index of
    0:
      Result := TFLIFImage.Create;
    {$ifdef flif_include_png}
    1:
      Result := TPngImage.Create;
    {$endif}
    {$ifdef flif_include_jpeg}
    2:
      Result := TJPEGImage.Create;
    {$endif}
    3:
      Result := TBitmap.Create;
  end;
end;

procedure TFormTestFlif.LabelAddressClick(Sender: TObject);
begin
  ShellExecute(Handle, nil, 'https://github.com/kangreon', nil, nil, SW_SHOWNORMAL);
end;

procedure TFormTestFlif.LabelAddressMouseEnter(Sender: TObject);
begin
  TLabel(Sender).Font.Color := clBlue;
end;

procedure TFormTestFlif.LabelAddressMouseLeave(Sender: TObject);
begin
  TLabel(Sender).Font.Color := clGray;
end;

procedure TFormTestFlif.ButtonLoadAndSaveClick(Sender: TObject);
var
  SourceImage, DestImage: TGraphic;
begin
  LabelView.Caption := 'View:';
  Memo2.Lines.Clear;

  FImage.SetSize(0, 0);

  SourceImage := GetImageFromIndex(ComboBoxFrom.ItemIndex);
  DestImage := GetImageFromIndex(ComboBoxTo.ItemIndex);
  try
    if not Assigned(SourceImage) then
    begin
      MessageBox(Handle,
        PChar('Image: "' + ComboBoxFrom.Text + '" not supported'), 'Load',
        MB_ICONERROR);

      Exit;
    end;

    SourceImage.LoadFromFile(ExtractFilePath(ParamStr(0)) + ComboBoxFrom.Text +
      '\' + ComboBoxName.Text + '.' + ComboBoxFrom.Text);

    Memo2.Lines.Add('source: ' + GetImageDescription(SourceImage));

    if not Assigned(DestImage) then
    begin
      FImage.Assign(SourceImage);

      MessageBox(Handle,
        PChar('Image: "' + ComboBoxTo.Text + '" not supported'), 'Load',
        MB_ICONERROR);

      Exit;
    end;

    DestImage.Assign(SourceImage);
    Memo2.Lines.Add('destination: ' + GetImageDescription(DestImage));

    try
      if Tag mod 2 = 0 then
      begin
        FImage.Assign(SourceImage);
        LabelView.Caption := 'View: source';
      end
      else
      begin
        FImage.Assign(DestImage);
        LabelView.Caption := 'View: save';
      end;
    finally
      Tag := Tag + 1;
    end;

    if CheckBoxSave.Checked then
      DestImage.SaveToFile(ExtractFilePath(ParamStr(0)) + ComboBoxTo.Text +
      '-OUT\' + ComboBoxName.Text + '.' + ComboBoxTo.Text);
  finally
    if Assigned(SourceImage) then
      SourceImage.Free;

    if Assigned(DestImage) then
      DestImage.Free;
  end;

  Invalidate;

  FImageLeft := ClientWidth div 4;
  FImageTop := ClientHeight div 4;
end;

procedure TFormTestFlif.ButtonTestClick(Sender: TObject);
var
  Test: TFlifTest;
begin
  Test := TFlifTest.Create;
  try
    if not Test.Test then
    begin
      MessageBox(Handle, PChar('Error code: ' + IntToStr(Test.ErrorIndex) +
        #13#10#13#10 + Test.ErrorDescription), 'Test error', MB_ICONERROR);
    end
    else
    begin
      MessageBox(Handle, 'Test done!', 'Test', MB_ICONINFORMATION);
    end;
  finally
    Test.Free;
  end;
end;

procedure TFormTestFlif.CheckBoxStretchClick(Sender: TObject);
begin
  Invalidate;
end;

procedure TFormTestFlif.CreateWnd;
begin
  inherited;

end;

procedure TFormTestFlif.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  LabelAddress.Left := ClientWidth - LabelAddress.Width - 5;
  LabelAddress.Top := ClientHeight - LabelAddress.Height - 5;
end;

procedure TFormTestFlif.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(FImage) then
    FImage.Free;
end;

procedure TFormTestFlif.FormCreate(Sender: TObject);
begin
  QueryPerformanceFrequency(FFreq);
  FTimeSum := 0;
  FTimeCount := 0;
  FImageLeft := 0;
  FImageTop := 150;
  FBackgroundTop := ButtonTest.Top + ButtonTest.Height + 20;

  DoubleBuffered := True;

  FImage := TFLIFImage.Create;

  ForceDirectories(ExtractFilePath(ParamStr(0)) + 'FLIF-OUT\');
  ForceDirectories(ExtractFilePath(ParamStr(0)) + 'PNG-OUT\');
  ForceDirectories(ExtractFilePath(ParamStr(0)) + 'JPEG-OUT\');
  ForceDirectories(ExtractFilePath(ParamStr(0)) + 'BMP-OUT\');

  ClientHeight := FBackgroundTop + ImageBackground.Picture.Graphic.Height + 20;
  ClientWidth := 520;

  Constraints.MinHeight := Height;
  Constraints.MinWidth := Width;
  PanelDrop.OnUpdate := DropUpdate;

  Caption := 'test FLIF';
end;

procedure TFormTestFlif.DropUpdate(Sender: TObject);
begin
  Memo2.Clear;
  Memo2.Lines.Add('Format: ' + PanelDrop.ImageType);
  Memo2.Lines.Add('Channels: ' + PanelDrop.Channels);
  Memo2.Lines.Add('Depth: ' + PanelDrop.Depth);
end;

procedure TFormTestFlif.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if Assigned(FImage) then
  begin
    FImageLeft := X - FImage.Width div 2;
    FImageTop := Y - FImage.Height div 2;

    Invalidate;
  end;
end;

procedure TFormTestFlif.FormPaint(Sender: TObject);
var
  Counter, CounterFinish: Int64;
  NewTime: Double;
begin
  Canvas.Draw(20, FBackgroundTop, ImageBackground.Picture.Graphic);

  QueryPerformanceCounter(Counter);
  if Assigned(FImage) then
  begin
    if CheckBoxStretch.Checked then
      Canvas.StretchDraw(TRect.Create(
          FImageLeft,
          FImageTop,
          FImageLeft + FImage.Width div 2,
          FImageTop + FImage.Height div 2),
      FImage)
    else
      Canvas.Draw(FImageLeft, FImageTop, FImage)
  end
  else
    Exit;
  QueryPerformanceCounter(CounterFinish);

  NewTime := (CounterFinish - Counter) / FFreq;
  FTimeSum := FTimeSum + NewTime;
  FTimeCount := FTimeCount + 1;
end;

{ TPanel }

procedure TPanel.CreateWnd;
var
  c, i: Integer;
begin
  inherited;
  FDropTarget := TDropTarget.Create(Handle, Self);
  FConverterExist := False;

  FLabel := nil;
  c := ControlCount;
  for i := 0 to c - 1 do
    if Controls[i] is TLabel then
    begin
      FLabel := TLabel(Controls[i]);
      FLabel.Caption := 'Drop your file here.'
    end;
end;

procedure TPanel.DestroyWnd;
begin
  inherited;
  FDropTarget.Free;
end;

procedure TPanel.Drop(const FileNames: array of string);
begin
  if FConverterExist then Exit;

  FConverterExist := True;
  FConverter := TFlifConverter.Create(FileNames[0]);
  FConverter.OnTerminate := ConverterTerminate;
  FConverter.FreeOnTerminate := True;
  FConverter.Start;

  FLabel.Caption := 'Processing...';
end;

function TPanel.DropAllowed(const FileNames: array of string): Boolean;
begin
  FLabel.Caption := 'Drop your file here.';
  Result := Assigned(FLabel) and not FConverterExist and (Length(FileNames) > 0) and
    TFlifConverter.IsValidFileName(FileNames[0]);
end;

function GetImageDescription(const Image: TGraphic): string;
var
  ImageType, Channels, Depth: string;
  PaletteExist: Boolean;
  LogPal: TMaxLogPalette;
  NumEntries: Cardinal;
begin
  PaletteExist := False;
  if Image is TFLIFImage then
  begin
    ImageType := 'FLIF';
    Channels := IntToStr(TFLIFImage(Image).Channels);
    Depth := IntToStr(TFLIFImage(Image).Depth);
    PaletteExist := TFlifImage(Image).PaletteExist;
  end
  else {$ifdef flif_include_png}if Image is TPngImage then
  begin
    ImageType := 'PNG';
    case TPngImage(Image).Header.ColorType of
      COLOR_GRAYSCALE:
        Channels := '1';
      COLOR_RGB:
        Channels := '3';
      COLOR_PALETTE:
        begin
          Channels := '1';
          PaletteExist := True;
        end;
      COLOR_RGBALPHA:
        Channels := '4';
    end;

    Depth := IntToStr(TPngImage(Image).Header.BitDepth);
  end
  else {$endif}{$ifdef flif_include_jpeg}if Image is TJPEGImage then
  begin
    ImageType := 'JPEG';
    Depth := '8';
    if TJpegImage(Image).PixelFormat = jf24Bit then
      Channels := '3'
    else
      Channels := '1';
  end
  else {$endif}if Image is TBitmap then
  begin
    ImageType := 'BMP';
    case TBitmap(Image).PixelFormat of
      pf8bit:
        begin
          Channels := '1';

          NumEntries := GetPaletteEntries(TBitmap(Image).Palette, 0, 256, LogPal.palPalEntry[0]);
          PaletteExist := not IsGrayScalePalette(@LogPal.palPalEntry, NumEntries)
        end;
      pf24bit:
        Channels := '3';
      pf32bit:
        Channels := '4';
    end;
  end
  else
    ImageType := 'Other';


  Result := ImageType + #13#10#9 +
    'Channels: ' + Channels + #13#10#9 +
    'Depth: ' + Depth + #13#10#9 +
    'Palette: ';

  if PaletteExist then
    Result := Result + 'yes'
  else
    Result := Result + 'no';
end;

procedure TPanel.ConverterTerminate(Sender: TObject);
begin
  FConverterExist := False;

  case FConverter.Flif.ImageType of
    fitRGB:
      ImageType := 'RGB';
    fitRGBA:
      ImageType := 'RGBA';
    fitHDR:
      ImageType := 'HDR';
    fitGRAY:
      ImageType := 'Gray';
    fitPALETTE:
      ImageType := 'Palette';
  end;

  Channels := IntToStr(FConverter.Flif.Channels);
  Depth := IntToStr(FConverter.Flif.Depth);
  if Assigned(FOnUpdate) then
    FOnUpdate(Self);

  if FConverter.ErrorExist then
  begin
    FLabel.Caption := 'Error!';
    MessageBox(Handle, PChar('Converting error: ' + FConverter.ErrorText), 'Error', MB_ICONERROR);
  end
  else
  begin
    FLabel.Caption := 'Done! Size: ' + Format('%.0f%%', [FConverter.Size]);
  end;
end;

end.

