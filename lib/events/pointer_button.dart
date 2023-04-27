part of '../waybright.dart';

/// A pointer button event.
class PointerButtonEvent {
  /// The pointer.
  final PointerDevice pointer;

  /// The number of the button whose state has been changed.
  final InputDeviceButton button;

  /// The button's code.
  final int code;

  /// Whether the button is pressed or not.
  final bool isPressed;

  /// The time elapsed in milliseconds.
  final int elapsedTimeMilliseconds;

  PointerButtonEvent(
    this.pointer,
    this.code,
    this.isPressed,
    this.elapsedTimeMilliseconds,
  ) : button = InputDeviceButton.values[code];
}
