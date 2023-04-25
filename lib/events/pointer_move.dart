part of '../waybright.dart';

/// A pointer move event.
class PointerMoveEvent {
  /// The pointer.
  PointerDevice pointer;

  /// The x-distance a pointer had moved.
  double deltaX;

  /// The y-distance a pointer had moved.
  double deltaY;

  /// The time elapsed in milliseconds.
  int elapsedTimeMilliseconds;

  PointerMoveEvent(
    this.pointer,
    this.deltaX,
    this.deltaY,
    this.elapsedTimeMilliseconds,
  );
}
