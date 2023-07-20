part of '../../waybright.dart';

/// A pointer relative move event.
class PointerRelativeMoveEvent extends PointerMoveEvent {
  /// The x-distance a pointer had moved.
  final double deltaX;

  /// The y-distance a pointer had moved.
  final double deltaY;

  PointerRelativeMoveEvent(
    PointerDevice pointer,
    this.deltaX,
    this.deltaY,
    Duration elapsedTime,
  ) : super(pointer, elapsedTime);
}
