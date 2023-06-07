part of '../waybright.dart';

/// An image event.
abstract class ImageEvent {
  /// The image.
  final Image image;

  ImageEvent(this.image);
}

/// An image destroying event.
class ImageDestroyingEvent extends ImageEvent {
  ImageDestroyingEvent(super.image);
}

/// An image load event.
class ImageLoadEvent extends ImageEvent {
  ImageLoadEvent(super.image);
}
