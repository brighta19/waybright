part of '../waybright.dart';

/// A pointer move event
class PointerMoveEvent {
  /// The x-distance a pointer had moved
  double deltaX;

  /// The y-distance a pointer had moved
  double deltaY;

  PointerMoveEvent(this.deltaX, this.deltaY);
}
