part of '../waybright.dart';

/// A keyboard key event.
class KeyboardKeyEvent {
  /// The keyboard.
  final KeyboardDevice keyboard;

  /// The key.
  final InputDeviceButton key;

  /// The key's code.
  final int code;

  /// Whether the button is pressed or not.
  final bool isPressed;

  /// The time elapsed in milliseconds.
  final int elapsedTimeMilliseconds;

  KeyboardKeyEvent(
    this.keyboard,
    this.code,
    this.isPressed,
    this.elapsedTimeMilliseconds,
  ) : key = InputDeviceButton.values[code];
}
