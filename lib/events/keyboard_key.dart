part of '../waybright.dart';

/// A keyboard key event.
class KeyboardKeyEvent {
  /// The keyboard.
  KeyboardDevice keyboard;

  /// The key's code.
  int keyCode;

  /// Whether the button is pressed or not.
  bool isPressed;

  /// The time elapsed in milliseconds.
  int elapsedTimeMilliseconds;

  KeyboardKeyEvent(
    this.keyboard,
    this.keyCode,
    this.isPressed,
    this.elapsedTimeMilliseconds,
  );
}
