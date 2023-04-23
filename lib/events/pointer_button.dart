part of '../waybright.dart';

/// A pointer button event.
class PointerButtonEvent {
  /// The number of the button whose state has been changed.
  int button;

  /// Whether the button is pressed or not.
  bool isPressed;

  /// The time elapsed in milliseconds.
  int elapsedTimeMilliseconds;

  PointerButtonEvent(this.button, this.isPressed, this.elapsedTimeMilliseconds);
}
