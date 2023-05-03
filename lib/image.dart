part of './waybright.dart';

class Image {
  Pointer<struct_waybright_image>? _imagePtr;

  /// The path to this image.
  String get path => _imagePtr != null ? _toString(_imagePtr!.ref.path) : "";

  /// The width of this image.
  int get width => _imagePtr?.ref.width ?? 0;

  /// The height of this image.
  int get height => _imagePtr?.ref.height ?? 0;
}
