part of '../waybright.dart';

/// A pointer movement event.
class PointerMovementEvent {
  /// The pointer.
  final PointerDevice pointer;

  /// The cursor's x distance relative to the window's position.
  final num windowCursorX;

  /// The cursor's y distance relative to the window's position.
  final num windowCursorY;

  /// The time elapsed in milliseconds.
  final int elapsedTimeMilliseconds;

  PointerMovementEvent(
    this.pointer,
    this.windowCursorX,
    this.windowCursorY,
    this.elapsedTimeMilliseconds,
  );
}
