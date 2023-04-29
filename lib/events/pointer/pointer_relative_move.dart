part of '../../waybright.dart';

/// A pointer relative move event.
class PointerRelativeMoveEvent extends PointerMoveEvent {
  /// The x-distance a pointer had moved.
  final double deltaX;

  /// The y-distance a pointer had moved.
  final double deltaY;

  PointerRelativeMoveEvent(
    pointer,
    this.deltaX,
    this.deltaY,
    elapsedTimeMilliseconds,
  ) : super(pointer, elapsedTimeMilliseconds);
}
