part of './waybright.dart';

class DestroyImageEvent {}

class Image {
  static final _imageInstances = <Image>[];

  static void _onEvent(int type, Pointer<Void> data) {
    var images = _imageInstances.toList();
    for (var image in images) {
      var imagePtr = data as Pointer<struct_waybright_image>;
      if (image._imagePtr != imagePtr) continue;

      switch (type) {
        case enum_wb_event_type.event_type_image_destroy:
          image.onDestroy?.call(DestroyImageEvent());
          _imageInstances.remove(image);
          break;
      }
    }
  }

  void Function(DestroyImageEvent)? onDestroy;

  Pointer<struct_waybright_image>? _imagePtr;

  Image() {
    _imageInstances.add(this);
  }

  bool get isReady => _imagePtr?.ref.is_ready ?? false;

  /// The path to this image.
  String get path => _imagePtr != null ? _toString(_imagePtr!.ref.path) : "";

  /// The width of this image.
  int get width => _imagePtr?.ref.width ?? 0;

  /// The height of this image.
  int get height => _imagePtr?.ref.height ?? 0;

  int get offsetX => _imagePtr?.ref.offset_x ?? 0;
  int get offsetY => _imagePtr?.ref.offset_y ?? 0;
}
