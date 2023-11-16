part of '../../waybright.dart';

/// A cursor image event.
class CursorImageEvent {
  /// The image.
  final Image? image;

  /// The vertical position of the hotspot.
  final int hotspotX;

  /// The horizontal position of the hotspot.
  final int hotspotY;

  CursorImageEvent(this.image, this.hotspotX, this.hotspotY);
}
