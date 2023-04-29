part of '../../waybright.dart';

/// A pointer button event.
class PointerButtonEvent extends PointerEvent {
  /// The number of the button whose state has been changed.
  final InputDeviceButton button;

  /// The button's code.
  final int code;

  /// Whether the button is pressed or not.
  final bool isPressed;

  PointerButtonEvent(
    pointer,
    this.code,
    this.isPressed,
    elapsedTimeMilliseconds,
  )   : button = InputDeviceButton.values[code],
        super(pointer, elapsedTimeMilliseconds);
}
