part of '../waybright.dart';

/// A pointer movement event.
class PointerMovementEvent {
  /// The pointer.
  PointerDevice pointer;

  /// The cursor's x distance relative to the window's position.
  num windowCursorX;

  /// The cursor's y distance relative to the window's position.
  num windowCursorY;

  /// The time elapsed in milliseconds.
  int elapsedTimeMilliseconds;

  PointerMovementEvent(
    this.pointer,
    this.windowCursorX,
    this.windowCursorY,
    this.elapsedTimeMilliseconds,
  );
}
