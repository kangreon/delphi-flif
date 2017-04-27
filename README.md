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

# License
All source code is distributed under license **GNU Lesser General Public License v3.0**. See [LICENSE](LICENSE) file.

All images are licensed **CC0 1.0 Universal (CC0 1.0)**.
