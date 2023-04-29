part of '../../waybright.dart';

/// A structure containing update information for a pointer.
class PointerUpdate<PointerEvent> {
  /// The pointer.
  final PointerDevice pointer;

  /// The event containing the update.
  final PointerEvent event;

  /// The cursor's vertical distance relative to the window's position.
  final double windowCursorX;

  /// The cursor's horizontal distance relative to the window's position.
  final double windowCursorY;

  PointerUpdate(
    this.pointer,
    this.event,
    this.windowCursorX,
    this.windowCursorY,
  );
}
