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
    PointerDevice pointer,
    this.code,
    this.isPressed,
    Duration elapsedTime,
  )   : button = InputDeviceButton.values[code],
        super(pointer, elapsedTime);
}
