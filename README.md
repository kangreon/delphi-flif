# Delphi FLIF
ObjectPascal wrapper over [FLIF](https://github.com/FLIF-hub/FLIF/) library and component **TFlifImage** for Rad Studio Delphi inherited from TGraphics.

**FLIF: Free Lossless Image Format** - http://flif.info

# FLIF Image
It is a non-visual component installed in RAD Studio Delphi development environment. After installing this component, IDE will be able to develop graphical applications using images in FLIF format. 

This component can be used in both graphical and console applications
* In graphics applications: load and display images on the screen using visual component TImage.
* In console applications: directly work with class TFlifImage = class (TGraphics).

# Features
* Loads and saves FLIF images: GRB GRBA PALETTE GRAY HDR(GRBA16)
* Draws the loaded image on TCanvas
* Show FLIF image on TImage
* Gets the FLIF image from:
  * TBitmap (Gray, Palette, rgb888, rgba8888)
  * TJpegImage (Gray (8 bits palette), rgb (24 bits))
  * TPngImage (Gray (8 bits), Palette (8 bits), rgb, rgba, rgba (64 bits))
* Converts a FLIF image to:
  * TBitmap
  * TJpegImage
  * TPngImage (except rgba (64 bits))
  
# How to install
1. Open project group `FLIF.groupproj` using RadStudio Delphi.
2. For packages `libflif.bpl` and` flifgraphics.bpl`, set "Build Configurations" = Debug.
3. Install the `libflif.bpl` package and then `flifgraphics.bpl`.
4. Go to `Tools - Options ... - Environment Options - Delphi Options - Library`.
5. Add to `Library path`  path to the compiled DCU files. For example, `D:\Delphi\delphi-flif\Win32\Debug\`.
6. Add to `Browsing path` path to the libflif source. For example, `D:\Delphi\delphi-flif\src\`.
7. Build and run `testFLIF` project.
8. Run test running application by clicking on the `Test!` button.
8. Go to the folder with the images and check that they are correct. For example, `D:\Delphi\delphi-flif\Win32\Debug\{BMP,FLIF,JPEG,PNG}-OUT`.
9. Choose another way to build (Debug, Release, 32-bit, 64-bit) and go to step 7.

# Example
```pascal
uses
  FLIFImage;
  
procedure ExampleLoadAndDraw(Canvas: TCanvas);
var
  Image: TFlifImage;
begin
  Image := TFlifImage.Create;
  try
    Image.LoadFromFile('image.flif');
    Canvas.Draw(0, 0, Image);
  finally
    Image.Free;
  end;
end;

procedure ExampleAssignAndSave(PngImage: TPngImage);
var
  Image: TFlifImage;
begin
  Image := TFlifImage.Create;
  try
    Image.Assign(PngImage);
    Image.SaveToFile('image.flif');
  finally
    Image.Free;
  end;
end;
```

# License
All source code is distributed under license **GNU Lesser General Public License v3.0**. See [LICENSE](LICENSE) file.

All images are licensed **CC0 1.0 Universal (CC0 1.0)**.
