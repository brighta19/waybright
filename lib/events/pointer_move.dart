part of '../waybright.dart';

/// A pointer move event.
class PointerMoveEvent {
  /// The pointer.
  final PointerDevice pointer;

  /// The x-distance a pointer had moved.
  final double deltaX;

  /// The y-distance a pointer had moved.
  final double deltaY;

  /// The time elapsed in milliseconds.
  final int elapsedTimeMilliseconds;

  PointerMoveEvent(
    this.pointer,
    this.deltaX,
    this.deltaY,
    this.elapsedTimeMilliseconds,
  );
}
