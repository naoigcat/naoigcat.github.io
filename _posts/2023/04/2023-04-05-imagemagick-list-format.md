---
layout: post
title:  ImageMagickの最小構成で使用できるフォーマットを出力する
date:   2023/04/05 12:25:24 +0900
tags:   imagemagick
---

## 最小構成でビルドする

DebianイメージをベースにしてImageMagickをビルドする場合は下記のライブラリが必要になる。

-   `ca-certificates`
-   `clang`
-   `curl`
-   `libgomp1`
-   `make`

### ca-certificates

`ca-certificates`がないとソースコードのダウンロード時にエラーになる。

```sh
$ docker run --rm -i debian:bullseye-slim bash <<-SCRIPT
apt-get update >/dev/null 2>&1
apt-get install -y --no-install-recommends curl >/dev/null 2>&1
curl -fsSL https://github.com
SCRIPT
curl: (77) error setting certificate verify locations:  CAfile: /etc/ssl/certs/ca-certificates.crt CApath: /etc/ssl/certs
```

### clang

`clang`がないとコンパイル時にエラーになる。

```sh
$ docker run --rm -i debian:bullseye-slim bash <<-SCRIPT
apt-get update >/dev/null 2>&1
apt-get install -y --no-install-recommends ca-certificates curl >/dev/null 2>&1
curl -fsSL https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.1-5.tar.gz | \
tar zx --strip-components 1 -C /tmp
cd /tmp
./configure --without-magick-plus-plus --disable-docs --disable-static
SCRIPT
checking build system type... aarch64-unknown-linux-gnu
checking host system type... aarch64-unknown-linux-gnu
checking target system type... aarch64-unknown-linux-gnu
checking for a BSD-compatible install... /usr/bin/install -c
checking whether build environment is sane... yes
checking for a race-free mkdir -p... /bin/mkdir -p
checking for gawk... no
checking for mawk... mawk
checking whether make sets $(MAKE)... no
checking whether make supports nested variables... no
checking whether UID '0' is supported by ustar format... yes
checking whether GID '0' is supported by ustar format... yes
checking how to create a ustar tar archive... gnutar
checking whether make supports nested variables... (cached) no
Configuring ImageMagick 7.1.1-5
checking whether build environment is sane... yes
checking whether make supports the include directive... no
checking for gcc... no
checking for cc... no
checking for cl.exe... no
checking for clang... no
configure: error: in `/tmp':
configure: error: no acceptable C compiler found in $PATH
See `config.log' for more details
```

### libgomp1

`libgomp1`がないと実行時にエラーになる。

```sh
$ docker run --rm -i debian:bullseye-slim bash <<-SCRIPT
apt-get update >/dev/null 2>&1
apt-get install -y --no-install-recommends ca-certificates clang curl make >/dev/null 2>&1
curl -fsSL https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.1-5.tar.gz | \
tar zx --strip-components 1 -C /tmp
cd /tmp
./configure --without-magick-plus-plus --disable-docs --disable-static >/dev/null 2>&1
make >/dev/null 2>&1
make install >/dev/null 2>&1
identify --version
SCRIPT
identify: error while loading shared libraries: libMagickCore-7.Q16HDRI.so.10: cannot open shared object file: No such file or directory
```

## 使用できるフォーマットを出力する

最小構成のDockerfileを作成する。

```dockerfile
FROM debian:bullseye-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        clang \
        curl \
        make \
        libgomp1 \
    && \
    curl -fsSL https://github.com/ImageMagick/ImageMagick/archive/refs/tags/7.1.1-5.tar.gz | \
    tar zx --strip-components 1 -C /tmp && \
    cd /tmp && \
    ./configure --without-magick-plus-plus --disable-docs --disable-static && \
    make && \
    make install && \
    ldconfig /usr/local/lib && \
    apt remove --autoremove --purge -y \
        ca-certificates \
        clang \
        curl \
        make \
    && \
    apt clean && \
    rm -rf /tmp/* /var/cache/apt/archives/* /var/lib/apt/lists/*
```

ビルドして使用できるフォーマットを出力する。

```sh
$ docker build . -t imagemagick
$ docker run --rm imagemagick identify -list format
   Format  Mode  Description
-------------------------------------------------------------------------------
      3FR  r--   Hasselblad CFV/H3D39II
      3G2  r--   Media Container
      3GP  r--   Media Container
        A* rw+   Raw alpha samples
      AAI* rw+   AAI Dune image
       AI  rw-   Adobe Illustrator CS2
     APNG  rw+   Animated Portable Network Graphics
      ART* rw-   PFS: 1st Publisher Clip Art
      ARW  r--   Sony Alpha Raw Image Format
   ASHLAR* -w+   Image sequence laid out in continuous irregular courses
      AVI  r--   Microsoft Audio/Visual Interleaved
      AVS* rw+   AVS X image
        B* rw+   Raw blue samples
    BAYER* rw+   Raw mosaiced samples
   BAYERA* rw+   Raw mosaiced and alpha samples
      BGR* rw+   Raw blue, green, and red samples
     BGRA* rw+   Raw blue, green, red, and alpha samples
     BGRO* rw+   Raw blue, green, red, and opacity samples
      BMP* rw-   Microsoft Windows bitmap image
     BMP2* rw-   Microsoft Windows bitmap image (V2)
     BMP3* rw-   Microsoft Windows bitmap image (V3)
      BRF* -w-   BRF ASCII Braille format
        C* rw+   Raw cyan samples
      CAL* r--   Continuous Acquisition and Life-cycle Support Type 1
           Specified in MIL-R-28002 and MIL-PRF-28002
     CALS* r--   Continuous Acquisition and Life-cycle Support Type 1
           Specified in MIL-R-28002 and MIL-PRF-28002
   CANVAS* r--   Constant image uniform color
  CAPTION* r--   Caption
      CIN* rw-   Cineon Image File
      CIP* -w-   Cisco IP phone image format
     CLIP* rw+   Image Clip Mask
     CMYK* rw+   Raw cyan, magenta, yellow, and black samples
    CMYKA* rw+   Raw cyan, magenta, yellow, black, and alpha samples
      CR2  r--   Canon Digital Camera Raw Image Format
      CR3  r--   Canon Digital Camera Raw Image Format
      CRW  r--   Canon Digital Camera Raw Image Format
     CUBE* r--   Cube LUT
      CUR* rw-   Microsoft icon
      CUT* r--   DR Halo
     DATA* rw+   Base64-encoded inline images
      DCM* r--   Digital Imaging and Communications in Medicine image
           DICOM is used by the medical community for images like X-rays.  The
           specification, "Digital Imaging and Communications in Medicine
           (DICOM)", is available at http://medical.nema.org/.  In particular,
           see part 5 which describes the image encoding (RLE, JPEG, JPEG-LS),
           and supplement 61 which adds JPEG-2000 encoding.
      DCR  r--   Kodak Digital Camera Raw Image File
    DCRAW  r--   Raw Photo Decoder (dcraw)
      DCX* rw+   ZSoft IBM PC multi-page Paintbrush
      DDS* rw+   Microsoft DirectDraw Surface
      DNG  r--   Digital Negative
      DPX* rw-   SMPTE 268M-2003 (DPX 2.0)
           Digital Moving Picture Exchange Bitmap, Version 2.0.
           See SMPTE 268M-2003 specification at http://www.smtpe.org
           
     DXT1* rw+   Microsoft DirectDraw Surface
     DXT5* rw+   Microsoft DirectDraw Surface
     EPDF  rw-   Encapsulated Portable Document Format
      EPI  rw-   Encapsulated PostScript Interchange format
      EPS  rw-   Encapsulated PostScript
     EPS2  -w-   Level II Encapsulated PostScript
     EPS3  -w+   Level III Encapsulated PostScript
     EPSF  rw-   Encapsulated PostScript
     EPSI  rw-   Encapsulated PostScript Interchange format
      ERF  r--   Epson RAW Format
 FARBFELD* rw-   Farbfeld
      FAX* rw+   Group 3 FAX
           FAX machines use non-square pixels which are 1.5 times wider than
           they are tall but computer displays use square pixels, therefore
           FAX images may appear to be narrow unless they are explicitly
           resized using a geometry of "150x100%".
           
       FF* rw-   Farbfeld
     FILE* r--   Uniform Resource Locator (file://)
     FITS* rw+   Flexible Image Transport System
     FL32* rw-   FilmLight
      FLV  rw+   Flash Video Stream
  FRACTAL* r--   Plasma fractal image
      FTP* ---   Uniform Resource Locator (ftp://)
      FTS* rw+   Flexible Image Transport System
     FTXT* rw-   Formatted text image
        G* rw+   Raw green samples
       G3* rw-   Group 3 FAX
       G4* rw-   Group 4 FAX
      GIF* rw+   CompuServe graphics interchange format
    GIF87* rw-   CompuServe graphics interchange format (version 87a)
 GRADIENT* r--   Gradual linear passing from one shade to another
     GRAY* rw+   Raw gray samples
    GRAYA* rw+   Raw gray and alpha samples
     HALD* r--   Identity Hald color lookup table image
      HDR* rw+   Radiance RGBE image format
HISTOGRAM* -w-   Histogram of the image
      HRZ* rw-   Slow Scan TeleVision
      HTM* -w-   Hypertext Markup Language and a client-side image map
     HTML* -w-   Hypertext Markup Language and a client-side image map
     HTTP* ---   Uniform Resource Locator (http://)
    HTTPS* r--   Uniform Resource Locator (https://)
      ICB* rw-   Truevision Targa image
      ICO* rw+   Microsoft icon
     ICON* rw-   Microsoft icon
      IIQ  r--   Phase One Raw Image Format
     INFO  -w+   The image format and characteristics
   INLINE* rw+   Base64-encoded inline images
      IPL* rw+   IPL Image Sequence
   ISOBRL* -w-   ISO/TR 11548-1 format
  ISOBRL6* -w-   ISO/TR 11548-1 format 6dot
      JNX* r--   Garmin tile format
     JSON  -w+   The image format and characteristics
        K* rw+   Raw black samples
      K25  r--   Kodak Digital Camera Raw Image Format
      KDC  r--   Kodak Digital Camera Raw Image Format
    LABEL* r--   Image label
        M* rw+   Raw magenta samples
      M2V  rw+   MPEG Video Stream
      M4V  rw+   Raw VIDEO-4 Video
      MAC* r--   MAC Paint
      MAP* rw-   Colormap intensities and indices
     MASK* rw+   Image Clip Mask
      MAT  rw+   MATLAB level 5 image format
    MATTE* -w+   MATTE format
      MEF  r--   Mamiya Raw Image File
     MIFF* rw+   Magick Image File Format
      MKV  rw+   Multimedia Container
     MONO* rw-   Raw bi-level bitmap
      MOV  rw+   MPEG Video Stream
      MP4  rw+   VIDEO-4 Video Stream
      MPC* rw+   Magick Pixel Cache image format
     MPEG  rw+   MPEG Video Stream
      MPG  rw+   MPEG Video Stream
      MRW  r--   Sony (Minolta) Raw Image File
      MSL* ---   Magick Scripting Language
     MSVG* -w+   ImageMagick's own SVG internal renderer
      MTV* rw+   MTV Raytracing image format
      MVG* rw-   Magick Vector Graphics
      NEF  r--   Nikon Digital SLR Camera Raw Image File
      NRW  r--   Nikon Digital SLR Camera Raw Image File
     NULL* rw-   Constant image of uniform color
        O* rw+   Raw opacity samples
      ORA  ---   OpenRaster format
      ORF  r--   Olympus Digital Camera Raw Image File
      OTB* rw-   On-the-air bitmap
      PAL* rw-   16bit/pixel interleaved YUV
     PALM* rw+   Palm pixmap
      PAM* rw+   Common 2-dimensional bitmap format
    PANGO* ---   Pango Markup Language
  PATTERN* r--   Predefined pattern
      PBM* rw+   Portable bitmap format (black and white)
      PCD* rw-   Photo CD
     PCDS* rw-   Photo CD
      PCL  rw+   Printer Control Language
      PCT* rw-   Apple Macintosh QuickDraw/PICT
      PCX* rw-   ZSoft IBM PC Paintbrush
      PDB* rw+   Palm Database ImageViewer Format
      PDF  rw+   Portable Document Format
     PDFA  rw+   Portable Document Archive Format
      PEF  r--   Pentax Electronic File
      PES* r--   Embrid Embroidery Format
      PFM* rw+   Portable float format
      PGM* rw+   Portable graymap format (gray scale)
      PGX* rw-   JPEG 2000 uncompressed format
      PHM* rw+   Portable half float format
    PICON* rw-   Personal Icon
     PICT* rw-   Apple Macintosh QuickDraw/PICT
      PIX* r--   Alias/Wavefront RLE image format
   PLASMA* r--   Plasma fractal image
      PNM* rw+   Portable anymap
POCKETMOD  rw+   Pocketmod Personal Organizer
      PPM* rw+   Portable pixmap format (color)
       PS  rw+   PostScript
      PS2  -w+   Level II PostScript
      PS3  -w+   Level III PostScript
      PSB* rw+   Adobe Large Document Format
      PSD* rw+   Adobe Photoshop bitmap
      PWP* r--   Seattle Film Works
      QOI* rw-   Quite OK image format
        R* rw+   Raw red samples
RADIAL-GRADIENT* r--   Gradual radial passing from one shade to another
      RAF  r--   Fuji CCD-RAW Graphic File
      RAS* rw+   SUN Rasterfile
      RAW  r--   Raw
      RGB* rw+   Raw red, green, and blue samples
   RGB565* r--   Raw red, green, blue samples in 565 format
     RGBA* rw+   Raw red, green, blue, and alpha samples
     RGBO* rw+   Raw red, green, blue, and opacity samples
      RGF* rw-   LEGO Mindstorms EV3 Robot Graphic Format (black and white)
      RLA* r--   Alias/Wavefront image
      RLE* r--   Utah Run length encoded image
      RMF  r--   Raw Media Format
      RW2  r--   Panasonic Lumix Raw Image
      SCR* r--   ZX-Spectrum SCREEN$
SCREENSHOT* r--   Screen shot
      SCT* r--   Scitex HandShake
      SFW* r--   Seattle Film Works
      SGI* rw+   Irix RGB image
    SHTML* -w-   Hypertext Markup Language and a client-side image map
      SIX* rw-   DEC SIXEL Graphics Format
    SIXEL* rw-   DEC SIXEL Graphics Format
SPARSE-COLOR* -w+   Sparse Color
      SR2  r--   Sony Raw Format 2
      SRF  r--   Sony Raw Format
  STEGANO* r--   Steganographic image
   STRIMG* rw-   String to image and back
      SUN* rw+   SUN Rasterfile
      SVG* rw+   Scalable Vector Graphics
     SVGZ* -w+   Compressed Scalable Vector Graphics
     TEXT* r--   Text
      TGA* rw-   Truevision Targa image
THUMBNAIL* -w+   EXIF Profile Thumbnail
     TILE* r--   Tile image with a texture
      TIM* r--   PSX TIM
      TM2* r--   PS2 TIM2
      TXT* rw+   Text
     UBRL* -w-   Unicode Text format
    UBRL6* -w-   Unicode Text format 6dot
      UIL* -w-   X-Motif UIL table
     UYVY* rw-   16bit/pixel interleaved YUV
      VDA* rw-   Truevision Targa image
    VICAR* rw-   Video Image Communication And Retrieval
      VID* rw+   Visual Image Directory
     VIFF* rw+   Khoros Visualization image
     VIPS* rw+   VIPS image
      VST* rw-   Truevision Targa image
     WBMP* rw-   Wireless Bitmap (level 0) image
     WEBM  rw+   Open Web Media
      WMV  rw+   Windows Media Video
      WPG* rw-   Word Perfect Graphics
      X3F  r--   Sigma Camera RAW Picture File
      XBM* rw-   X Windows system bitmap (black and white)
       XC* r--   Constant image uniform color
      XCF* r--   GIMP image
      XPM* rw-   X Windows system pixmap (color)
      XPS  r--   Microsoft XML Paper Specification
       XV* rw+   Khoros Visualization image
        Y* rw+   Raw yellow samples
     YAML  -w+   The image format and characteristics
    YCbCr* rw+   Raw Y, Cb, and Cr samples
   YCbCrA* rw+   Raw Y, Cb, Cr, and alpha samples
      YUV* rw-   CCIR 601 4:1:1 or 4:2:2

* native blob support
r read support
w write support
+ support for multiple images
```
