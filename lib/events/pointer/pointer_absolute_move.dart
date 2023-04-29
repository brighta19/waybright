part of '../../waybright.dart';

/// A pointer absolute move event.
class PointerAbsoluteMoveEvent extends PointerMoveEvent {
  /// The monitor that the pointer teleported to.
  final Monitor monitor;

  /// The pointer's horizontal position on the [monitor].
  final double x;

  /// The pointer's vertical position on the [monitor].
  final double y;

  PointerAbsoluteMoveEvent(
    pointer,
    this.monitor,
    this.x,
    this.y,
    elapsedTimeMilliseconds,
  ) : super(pointer, elapsedTimeMilliseconds);
}
