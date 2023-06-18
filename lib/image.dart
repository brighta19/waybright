// TODO: Maybe download images from the internet.

part of './waybright.dart';

/// An image.
class Image {
  static final _imageInstances = <Pointer<struct_waybright_image>, Image>{};

  static void _onEvent(int type, Pointer<Void> data) {
    var imagePtr = data as Pointer<struct_waybright_image>;
    var image = _imageInstances[imagePtr];
    if (image == null) return;

    switch (type) {
      case enum_wb_event_type.event_type_image_destroy:
        image.onDestroying?.call(ImageDestroyingEvent(image));
        _imageInstances.remove(image);
        break;
      case enum_wb_event_type.event_type_image_load:
        image.onLoad?.call(ImageLoadEvent(image));
        break;
      default:
        throw ArgumentError("Internal error: unknown event type $type");
    }
  }

  final Pointer<struct_waybright_image> _imagePtr;

  Image._fromPointer(this._imagePtr) {
    _imageInstances[_imagePtr] = this;
    _imagePtr.ref.handle_event = Pointer.fromFunction(_onEvent);
  }

  /// A handler that is called when the image is being destroyed.
  void Function(ImageDestroyingEvent event)? onDestroying;

  /// A handler that is called when the image is loaded.
  ///
  /// The handler will not be called if the image is already loaded. Use
  /// [isLoaded] to check if the image is loaded.
  void Function(ImageLoadEvent event)? onLoad;

  /// Whether this image is loaded.
  bool get isLoaded => _imagePtr.ref.is_loaded;

  /// The path to this image.
  String get path => _toDartString(_imagePtr.ref.path) ?? "";

  /// The horizontal size of this image.
  int get width => _imagePtr.ref.width;

  /// The vertical size of this image.
  int get height => _imagePtr.ref.height;
}
