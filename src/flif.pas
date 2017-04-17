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

unit flif;

interface

uses
  Windows;

type
  FLIF_DECODER = Pointer;
  TFLIFDecoder = FLIF_DECODER;

  FLIF_IMAGE = Pointer;
  TFLIFImagePointer = FLIF_IMAGE;

  FLIF_INFO = Pointer;
  TFLIFInfo = FLIF_INFO;

  FLIF_ENCODER = Pointer;
  TFLIFEncoder = FLIF_ENCODER;

const
  LIBRARY_FLIF = 'libflif.dll';

{$I flif.inc}

///
///  flif_common.h
///  add3cc6 on 6 Feb 2017
///

/// <summary>
///   RGBA
/// </summary>
function flif_create_image(Width, Height: UInt32): TFLIFImagePointer; cdecl external LIBRARY_FLIF;
function flif_create_image_HDR(Width, Height: UInt32): TFLIFImagePointer; cdecl external LIBRARY_FLIF;
{$ifdef flif_master}
function flif_create_image_RGB(Width, Height: UInt32): TFLIFImagePointer; cdecl external LIBRARY_FLIF;
function flif_create_image_GRAY(Width, Height: UInt32): TFLIFImagePointer; cdecl external LIBRARY_FLIF;
function flif_create_image_PALETTE(Width, Height: UInt32): TFLIFImagePointer; cdecl external LIBRARY_FLIF;
{$endif}

function flif_import_image_RGBA(Width, Height: UInt32; const RGBA: Pointer;
  RGBAStride: UInt32): TFLIFImagePointer; cdecl external LIBRARY_FLIF;
function flif_import_image_RGB(Width, Height: UInt32; const RGB: Pointer;
  RGBStride: UInt32): TFLIFImagePointer; cdecl external LIBRARY_FLIF;
function flif_import_image_GRAY(Width, Height: UInt32; const GRAY: Pointer;
  GRAYStride: UInt32): TFLIFImagePointer; cdecl external LIBRARY_FLIF;
{$ifdef flif_master}
function flif_import_image_PALETTE(Width, Height: UInt32; const GRAY: Pointer;
  GRAYStride: UInt32): TFLIFImagePointer; cdecl external LIBRARY_FLIF;
{$endif}
procedure flif_destroy_image(Image: TFLIFImagePointer); cdecl external LIBRARY_FLIF;

function flif_image_get_width(Image: TFLIFImagePointer): UInt32; cdecl external LIBRARY_FLIF;
function flif_image_get_height(Image: TFLIFImagePointer): UInt32; cdecl external LIBRARY_FLIF;
function flif_image_get_nb_channels(Image: TFLIFImagePointer): UInt8; cdecl external LIBRARY_FLIF;
function flif_image_get_depth(Image: TFLIFImagePointer): UInt8; cdecl external LIBRARY_FLIF;
{$ifdef flif_master}
/// <summary>
///    0 = no palette, 1-256 = nb of colors in palette
/// </summary>
function flif_image_get_palette_size(Image: TFLIFImagePointer): UInt32; cdecl external LIBRARY_FLIF;
/// <summary>
///   puts RGBA colors in buffer (4*palette_size bytes)
/// </summary>
procedure flif_image_get_palette(Image: TFLIFImagePointer; Buffer: Pointer); cdecl external LIBRARY_FLIF;
/// <summary>
///   puts RGBA colors in buffer (4*palette_size bytes)
/// </summary>
procedure flif_image_set_palette(Image: TFLIFImagePointer; const Buffer: Pointer; PaletteSize: UInt32); cdecl external LIBRARY_FLIF;
{$endif}
function flif_image_get_frame_delay(Image: TFLIFImagePointer): UInt32; cdecl external LIBRARY_FLIF;
procedure flif_image_set_frame_delay(Image: TFLIFImagePointer; Delay: UInt32); cdecl external LIBRARY_FLIF;

procedure flif_image_set_metadata(Image: TFLIFImagePointer; const ChunkName: PAnsiChar;
  Data: PByte; Length: NativeUInt); cdecl external LIBRARY_FLIF;
function flif_image_get_metadata(Image: TFLIFImagePointer; const ChunkName: PAnsiChar;
  var Data: PByte; var Length: NativeUInt): UInt8; cdecl external LIBRARY_FLIF;
procedure flif_image_free_metadata(Image: TFLIFImagePointer; Data: PByte); cdecl external LIBRARY_FLIF;

{$ifdef flif_master}
procedure flif_image_write_row_PALETTE8(Image: TFLIFImagePointer; Row: UInt32;
  const Buffer: Pointer; BufferSizeBytes: NativeUInt); cdecl external LIBRARY_FLIF;
procedure flif_image_read_row_PALETTE8(Image: TFLIFImagePointer; Row: UInt32;
  Buffer: Pointer; BufferSizeBytes: NativeUInt); cdecl external LIBRARY_FLIF;

procedure flif_image_write_row_GRAY8(Image: TFLIFImagePointer; Row: UInt32;
  const Buffer: Pointer; BufferSizeBytes: NativeUInt); cdecl external LIBRARY_FLIF;
procedure flif_image_read_row_GRAY8(Image: TFLIFImagePointer; Row: UInt32;
  Buffer: Pointer; BufferSizeBytes: NativeUInt); cdecl external LIBRARY_FLIF;
{$endif}
procedure flif_image_write_row_RGBA8(Image: TFLIFImagePointer; Row: UInt32;
  const Buffer: Pointer; BufferSizeBytes: NativeUInt); cdecl external LIBRARY_FLIF;
procedure flif_image_read_row_RGBA8(Image: TFLIFImagePointer; Row: UInt32;
  Buffer: Pointer; BufferSizeBytes: NativeUInt); cdecl external LIBRARY_FLIF;

procedure flif_image_write_row_RGBA16(Image: TFLIFImagePointer; Row: UInt32;
  const Buffer: Pointer; BufferSizeBytes: NativeUInt); cdecl external LIBRARY_FLIF;
procedure flif_image_read_row_RGBA16(Image: TFLIFImagePointer; Row: UInt32;
  Buffer: Pointer; BufferSizeBytes: NativeUInt); cdecl external LIBRARY_FLIF;

procedure flif_free_memory(Buffer: Pointer); cdecl external LIBRARY_FLIF;

///
///  flif_dec.h
///  11d73ae on 6 Sep 2016
///

/// <summary>
///   initialize a FLIF decoder
/// </summary>
function flif_create_decoder: TFLIFDecoder; cdecl external LIBRARY_FLIF;


/// <summary>
///   decode a given FLIF file
/// </summary>
function flif_decoder_decode_file(Decoder: TFLIFDecoder;
  const FileName: PAnsiChar): Int32; cdecl external LIBRARY_FLIF;

/// <summary>
///   decode a FLIF blob in memory: buffer should point to the blob and
///  buffer_size_bytes should be its size
/// </summary>
function flif_decoder_decode_memory(Decoder: TFLIFDecoder; const Buffer: PByte;
  BufferSizeBytes: NativeUInt): Int32; cdecl external LIBRARY_FLIF;


/// <summary>
///   returns the number of frames (1 if it is not an animation)
/// </summary>
function flif_decoder_num_images(Decoder: TFLIFDecoder): NativeUInt; cdecl external LIBRARY_FLIF;

/// <summary>
///   only relevant for animations: returns the loop count (0 = loop forever)
/// </summary>
function flif_decoder_num_loops(Decoder: TFLIFDecoder): Int32; cdecl external LIBRARY_FLIF;

/// <summary>
///    returns a pointer to a given frame, counting from 0 (use index=0 for still images)
/// </summary>
function flif_decoder_get_image(Decoder: TFLIFDecoder; Index: NativeUInt): TFLIFImagePointer; cdecl external LIBRARY_FLIF;


/// <summary>
///   release an decoder (has to be called after decoding is done, to avoid memory leaks)
/// </summary>
procedure flif_destroy_decoder(Decoder: TFLIFDecoder); cdecl external LIBRARY_FLIF;

/// <summary>
///   abort a decoder (can be used before decoding is completed)
/// </summary>
function flif_abort_decoder(Decoder: TFLIFDecoder): Integer; cdecl external LIBRARY_FLIF;


/// <summary>
/// <para>
///   decode options, all optional, can be set after decoder initialization and
///  before actual decoding
/// </para>
/// <para>
///   default: no (0)
/// </para>
/// </summary>
procedure flif_decoder_set_crc_check(Decoder: TFLIFDecoder; CrcCheck: Int32); cdecl external LIBRARY_FLIF;

/// <summary>
///   valid quality: 0-100
/// </summary>
procedure flif_decoder_set_quality(Decoder: TFLIFDecoder; Quality: Int32); cdecl external LIBRARY_FLIF;

/// <summary>
///   valid scales: 1,2,4,8,16,...
/// </summary>
procedure flif_decoder_set_scale(Decoder: TFLIFDecoder; Scale: UInt32); cdecl external LIBRARY_FLIF;
procedure flif_decoder_set_resize(Decoder: TFLIFDecoder; Width, Height: UInt32); cdecl external LIBRARY_FLIF;
procedure flif_decoder_set_fit(Decoder: TFLIFDecoder; Width, Height: UInt32); cdecl external LIBRARY_FLIF;

type
  TFLIFDecoderCallback = function(Quality: Int32; BytesRead: Int64): UInt32; cdecl;

/// <summary>
///   Progressive decoding: set a callback function. The callback will be called
///  after a certain quality is reached, and it should return the desired next
///  quality that should be reached before it will be called again.
///  The qualities are expressed on a scale from 0 to 10000 (not 0 to 100!) for
///  fine-grained control.
/// </summary>
procedure flif_decoder_set_callback(Decoder: TFLIFDecoder;
  CallbackFunction: TFLIFDecoderCallback); cdecl external LIBRARY_FLIF;

/// <summary>
///   valid quality: 0-10000
/// </summary>
procedure flif_decoder_set_first_callback_quality(Decoder: TFLIFDecoder; Quality: Int32); cdecl external LIBRARY_FLIF;


/// <summary>
/// <para>
///   Reads the header of a FLIF file and packages it as a FLIF_INFO struct.
/// </para>
/// <para>
///   May return a null pointer if the file is not in the right format.
/// </para>
/// <para>
///   The caller takes ownership of the return value and must call flif_destroy_info().
/// </para>
/// </summary>
function flif_read_info_from_memory(const Buffer: Pointer;
  BufferSizeBytes: NativeUInt): TFLIFInfo; cdecl external LIBRARY_FLIF;

/// <summary>
///   deallocator function for FLIF_INFO
/// </summary>
procedure flif_destroy_info(Info: TFLIFInfo); cdecl external LIBRARY_FLIF;


/// <summary>
///   get the image width
/// </summary>
function flif_info_get_width(Info: TFLIFInfo): UInt32; cdecl external LIBRARY_FLIF;

/// <summary>
///   get the image height
/// </summary>
function flif_info_get_height(Info: TFLIFInfo): UInt32; cdecl external LIBRARY_FLIF;

/// <summary>
///   get the number of color channels
/// </summary>
function flif_info_get_nb_channels(Info: TFLIFInfo): UInt8; cdecl external LIBRARY_FLIF;

/// <summary>
///   get the number of bits per channel
/// </summary>
function flif_info_get_depth(Info: TFLIFInfo): UInt8; cdecl external LIBRARY_FLIF;

/// <summary>
///   get the number of animation frames
/// </summary>
function flif_info_num_images(Info: TFLIFInfo): NativeUInt; cdecl external LIBRARY_FLIF;

///
///  flif_enc.h
///  bf330d4 on 28 Feb 2017
///

/// <summary>
///   initialize a FLIF encoder
/// </summary>
function flif_create_encoder: TFLIFEncoder; cdecl external LIBRARY_FLIF;
/// <summary>
///   give it an image to encode; add more than one image to encode an animation
/// </summary>
procedure flif_encoder_add_image(Encoder: TFLIFEncoder; Image: TFLIFImagePointer); cdecl external LIBRARY_FLIF;
/// <summary>
///   encode to a file
/// </summary>
function flif_encoder_encode_file(Encoder: TFLIFEncoder; const FileName: PAnsiChar): Int32; cdecl external LIBRARY_FLIF;
/// <summary>
///   encode to memory (afterwards, buffer will point to the blob and
///  buffer_size_bytes contains its size)
/// </summary>
function flif_encoder_encode_memory(Encoder: TFLIFEncoder; var Buffer: Pointer;
   var BufferSizeBytes: NativeUInt): Int32; cdecl external LIBRARY_FLIF;
/// <summary>
///   release an encoder (has to be called to avoid memory leaks)
/// </summary>
procedure flif_destroy_encoder(Encoder: TFLIFEncoder); cdecl external LIBRARY_FLIF;

///
///  encoder options (these are all optional, the defaults should be fine)
///

/// <summary>
///   0 = -N, 1 = -I (default: -I)
/// </summary>
procedure flif_encoder_set_interlaced(Encoder: TFLIFEncoder; Interlaced: UInt32); cdecl external LIBRARY_FLIF;
/// <summary>
///   default: 2 (-R)
/// </summary>
procedure flif_encoder_set_learn_repeat(Encoder: TFLIFEncoder; LearnRepeats: UInt32); cdecl external LIBRARY_FLIF;
/// <summary>
///   0 = -B, 1 = default
/// </summary>
procedure flif_encoder_set_auto_color_buckets(Encoder: TFLIFEncoder; Acb: UInt32); cdecl external LIBRARY_FLIF;
/// <summary>
///   default: 512  (max palette size)
/// </summary>
procedure flif_encoder_set_palette_size(Encoder: TFLIFEncoder; PaletteSize: Int32); cdecl external LIBRARY_FLIF;
/// <summary>
///   default: 1 (-L)
/// </summary>
procedure flif_encoder_set_lookback(Encoder: TFLIFEncoder; Lookback: Int32); cdecl external LIBRARY_FLIF;
/// <summary>
///   default: 30 (-D)
/// </summary>
procedure flif_encoder_set_divisor(Encoder: TFLIFEncoder; Divisor: Int32); cdecl external LIBRARY_FLIF;
/// <summary>
///   default: 50 (-M)
/// </summary>
procedure flif_encoder_set_min_size(Encoder: TFLIFEncoder; MinSize: Int32); cdecl external LIBRARY_FLIF;
/// <summary>
///   default: 64 (-T)
/// </summary>
procedure flif_encoder_set_split_threshold(Encoder: TFLIFEncoder; Threshold: Int32); cdecl external LIBRARY_FLIF;
/// <summary>
///   0 = default, 1 = -K
/// </summary>
procedure flif_encoder_set_alpha_zero_lossless(Encoder: TFLIFEncoder); cdecl external LIBRARY_FLIF;
/// <summary>
///   default: 2  (-X)
/// </summary>
procedure flif_encoder_set_chance_cutoff(Encoder: TFLIFEncoder; Cutoff: Int32); cdecl external LIBRARY_FLIF;
/// <summary>
///   default: 19 (-Z)
/// </summary>
procedure flif_encoder_set_chance_alpha(Encoder: TFLIFEncoder; Alpha: Int32); cdecl external LIBRARY_FLIF;
/// <summary>
///   0 = no CRC, 1 = add CRC
/// </summary>
procedure flif_encoder_set_crc_check(Encoder: TFLIFEncoder; CRCCheck: UInt32); cdecl external LIBRARY_FLIF;
/// <summary>
///   0 = -C, 1 = default
/// </summary>
procedure flif_encoder_set_channel_compact(Encoder: TFLIFEncoder; pcl: UInt32); cdecl external LIBRARY_FLIF;
/// <summary>
///   0 = -Y, 1 = default
/// </summary>
procedure flif_encoder_set_ycocg(Encoder: TFLIFEncoder; ycocg: UInt32); cdecl external LIBRARY_FLIF;
/// <summary>
///   0 = -S, 1 = default
/// </summary>
procedure flif_encoder_set_frame_shape(Encoder: TFLIFEncoder; frs: UInt32); cdecl external LIBRARY_FLIF;


/// <summary>
/// <para>
///    set amount of quality loss, 0 for no loss, 100 for maximum loss, negative
///  values indicate adaptive lossy (second image should be the saliency map)
/// </para>
/// <para>
///   default: 0 (lossless)
/// </para>
/// </summary>
procedure flif_encoder_set_lossy(Encoder: TFLIFEncoder; loss: Int32); cdecl external LIBRARY_FLIF;

///
///  flif.h
///  bdddad0 on 21 Apr 2016
///

/// <summary>
///   libflif version 0.2.0
/// </summary>
function FLIF_VERSION: UInt32; inline;
const
  FLIF_ABI_VERSION: UInt32 = 0;

implementation

function FLIF_VERSION: UInt32;
begin
  Result := (0 shl 16) or (0 shl 8) or (2);
end;

end.

