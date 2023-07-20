part of '../../waybright.dart';

/// A keyboard key event.
class KeyboardKeyEvent extends KeyboardEvent {
  /// The key.
  final InputDeviceButton key;

  /// The key's code.
  final int code;

  /// Whether the button is pressed or not.
  final bool isPressed;

  /// The time elapsed.
  final Duration elapsedTime;

  KeyboardKeyEvent(
    KeyboardDevice keyboard,
    this.code,
    this.isPressed,
    this.elapsedTime,
  )   : key = InputDeviceButton.values[code],
        super(keyboard);
}
